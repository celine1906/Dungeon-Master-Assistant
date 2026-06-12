"""
query.py -- Retrieval and generation backend for the DM assistant.

Two modes:
  live  -- fast, no LLM. Embeds question, returns top-3 entity full_texts directly.
           Use at the table when you need a quick fact.
  prep  -- full synthesis. top-8 + graph hydration + qwen2.5:14b streaming answer.
           Use during session planning for reasoning and what-if questions.

Usage (standalone):
    python query.py --question "what is the DC to escape the bookshelf?" --mode live
    python query.py --question "what if my party burns the library?" --mode prep
"""
from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Generator

import chromadb
import numpy as np
import ollama
from chromadb.config import Settings

sys.path.insert(0, str(Path(__file__).parent))

logging.basicConfig(level=logging.WARNING, format="%(levelname)s %(message)s")
log = logging.getLogger("query")

# ---------------------------------------------------------------------------
# Config defaults (overridden by app.py via function args)
# ---------------------------------------------------------------------------
DEFAULT_CHROMA_PATH   = Path(__file__).parent.parent / "chroma_db"
DEFAULT_ENTITIES_DIR  = Path(__file__).parent.parent / "data" / "entities"
DEFAULT_COLLECTION    = "candlekeep_joy_extradimensional"
DEFAULT_EMBED_MODEL   = "qwen3-embedding:latest"
DEFAULT_CHAT_MODEL    = "qwen2.5:14b"
DEFAULT_OLLAMA_HOST   = "http://localhost:11434"

# ---------------------------------------------------------------------------
# Generation prompt
# ---------------------------------------------------------------------------
# Prompt v1, deployed on streamlit

SYSTEM_PROMPT = """You are a Dungeon Master assistant for the D&D 5e adventure
"The Joy of Extradimensional Spaces" from Candlekeep Mysteries.

Answer using ONLY the provided context. Never invent details not in the context.
Be direct and actionable — the DM may be at the table right now.

Format rules:
- Lead with the most critical information: DCs, HP, damage, conditions.
- Use short paragraphs, not bullet points unless listing multiple items.
- If the question involves a player action, describe what happens mechanically first, then narratively.
- If context is insufficient, say exactly what information is missing.
"""

# ---------------------------------------------------------------------------
# JSON entity store (loaded once, used for graph hydration)
# ---------------------------------------------------------------------------

def load_entity_store(entities_dir: Path) -> dict[str, dict]:
    """Load all entity JSON files into a flat id -> entity dict."""
    store: dict[str, dict] = {}
    if not entities_dir.exists():
        log.warning("Entities dir not found: %s", entities_dir)
        return store
    for fp in entities_dir.glob("*.json"):
        try:
            with fp.open(encoding="utf-8") as f:
                entities = json.load(f)
            for e in entities:
                store[e["id"]] = e
        except Exception as ex:
            log.warning("Could not load %s: %s", fp.name, ex)
    return store


# ---------------------------------------------------------------------------
# Embedding The Query
# ---------------------------------------------------------------------------

def embed_query(text: str, client: ollama.Client, model: str) -> list[float]:
    """Embed a single query string. Returns L2-normalized vector."""
    resp = client.embed(model=model, input=[text])
    vec = np.array(resp["embeddings"][0], dtype=np.float32)
    norm = np.linalg.norm(vec)
    if norm > 0:
        vec = vec / norm
    return vec.tolist()


# ---------------------------------------------------------------------------
# ChromaDB retrieval
# ---------------------------------------------------------------------------

def get_collection(chroma_path: Path, collection_name: str):
    client = chromadb.PersistentClient(
        path=str(chroma_path),
        settings=Settings(anonymized_telemetry=False),
    )
    return client.get_collection(collection_name)


def search(
    question: str,
    collection,
    ollama_client: ollama.Client,
    embed_model: str,
    n_results: int = 5,
    entity_type_filter: str | None = None,
) -> list[dict]:
    """
    Embed question and retrieve top-n entities from ChromaDB.
    Returns list of dicts with id, name, entity_type, full_text, metadata.
    """
    vector = embed_query(question, ollama_client, embed_model)

    where = {"entity_type": entity_type_filter} if entity_type_filter else None

    results = collection.query(
        query_embeddings=[vector],
        n_results=n_results,
        where=where,
        include=["documents", "metadatas", "distances"],
    )

    entities = []
    for i, doc_id in enumerate(results["ids"][0]):
        entities.append({
            "id": doc_id,
            "name": results["metadatas"][0][i].get("name", doc_id),
            "entity_type": results["metadatas"][0][i].get("entity_type", "unknown"),
            "full_text": results["documents"][0][i],
            "distance": results["distances"][0][i],
            "metadata": results["metadatas"][0][i],
        })
    return entities


# ---------------------------------------------------------------------------
# Graph hydration
# ---------------------------------------------------------------------------

def hydrate(entities: list[dict], store: dict[str, dict], depth: int = 1) -> list[dict]:
    """
    For each retrieved entity, add connected entities from the JSON store.
    Follows: contains_entity_ids, points_to, unlocks.
    Depth 1 = one hop only. Deduplicates by ID.
    """
    if depth == 0 or not store:
        return entities

    seen = {e["id"] for e in entities}
    extra: list[dict] = []

    for entity in entities:
        raw = store.get(entity["id"], {})
        connected_ids = (
            raw.get("contains_entity_ids", []) +
            raw.get("points_to", []) +
            raw.get("unlocks", []) +
            raw.get("leads_to", [])
        )
        for cid in connected_ids:
            if cid in seen:
                continue
            seen.add(cid)
            child = store.get(cid)
            if child:
                extra.append({
                    "id": child["id"],
                    "name": child.get("name", cid),
                    "entity_type": child.get("type", "unknown"),
                    "full_text": child.get("full_text", ""),
                    "distance": 0.0,
                    "metadata": {"entity_type": child.get("type", ""), "name": child.get("name", "")},
                })

    return entities + extra


# ---------------------------------------------------------------------------
# Context formatting
# ---------------------------------------------------------------------------

def format_context(entities: list[dict]) -> str:
    """Format retrieved entities into a context string for the LLM."""
    parts = []
    for e in entities:
        header = f"[{e['entity_type'].upper()}] {e['name']}"
        parts.append(f"{header}\n{e['full_text']}")
    return "\n\n---\n\n".join(parts)


# ---------------------------------------------------------------------------
# Live mode
# ---------------------------------------------------------------------------

def query_live(
    question: str,
    collection,
    ollama_client: ollama.Client,
    store: dict[str, dict],
    embed_model: str = DEFAULT_EMBED_MODEL,
    n_results: int = 3,
) -> dict:
    """
    Fast retrieval, no LLM. Returns structured result the UI can display.
    """
    entities = search(question, collection, ollama_client, embed_model, n_results)
    context = format_context(entities)
    return {
        "answer": context,
        "entities": entities,
        "mode": "live",
    }


# ---------------------------------------------------------------------------
# Prep mode (streaming)
# ---------------------------------------------------------------------------

def query_prep_stream(
    question: str,
    collection,
    ollama_client: ollama.Client,
    store: dict[str, dict],
    embed_model: str = DEFAULT_EMBED_MODEL,
    chat_model: str = DEFAULT_CHAT_MODEL,
    n_results: int = 8,
) -> tuple[Generator[str, None, None], list[dict]]:
    """
    Full synthesis with graph hydration and streaming LLM response.
    Returns (token_generator, source_entities).
    The caller iterates the generator to receive answer tokens.
    """
    entities = search(question, collection, ollama_client, embed_model, n_results)
    entities = hydrate(entities, store, depth=1)
    context = format_context(entities)

    user_message = f"Context:\n{context}\n\nDM Question: {question}"

    stream = ollama_client.chat(
        model=chat_model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message},
        ],
        stream=True,
        options={"temperature": 0.2},
    )

    def token_generator():
        for chunk in stream:
            token = chunk["message"]["content"]
            if token:
                yield token

    return token_generator(), entities


# ---------------------------------------------------------------------------
# CLI (for testing without UI)
# ---------------------------------------------------------------------------

def _cli():
    p = argparse.ArgumentParser(description="DM Assistant query CLI")
    p.add_argument("--question", "-q", required=True)
    p.add_argument("--mode", choices=["live", "prep"], default="live")
    p.add_argument("--chroma-path", type=Path, default=DEFAULT_CHROMA_PATH)
    p.add_argument("--entities-dir", type=Path, default=DEFAULT_ENTITIES_DIR)
    p.add_argument("--collection", default=DEFAULT_COLLECTION)
    p.add_argument("--embed-model", default=DEFAULT_EMBED_MODEL)
    p.add_argument("--chat-model", default=DEFAULT_CHAT_MODEL)
    p.add_argument("--ollama-host", default=DEFAULT_OLLAMA_HOST)
    args = p.parse_args()

    client = ollama.Client(host=args.ollama_host)
    collection = get_collection(args.chroma_path, args.collection)
    store = load_entity_store(args.entities_dir)

    print(f"\nQuestion: {args.question}")
    print(f"Mode: {args.mode}\n{'─' * 60}\n")

    if args.mode == "live":
        result = query_live(args.question, collection, client, store, args.embed_model)
        print(result["answer"])
        print(f"\n{'─' * 60}")
        print(f"Sources: {[e['name'] for e in result['entities']]}")
    else:
        gen, entities = query_prep_stream(
            args.question, collection, client, store,
            args.embed_model, args.chat_model
        )
        for token in gen:
            print(token, end="", flush=True)
        print(f"\n\n{'─' * 60}")
        print(f"Sources ({len(entities)}): {[e['name'] for e in entities]}")


if __name__ == "__main__":
    _cli()