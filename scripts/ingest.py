"""
Ingestion pipeline: hand-authored JSON entities -> Qwen3 embeddings (via Ollama) -> ChromaDB.

Prerequisites:
    1. `ollama serve` is running.
    2. The embedding model is pulled: `ollama pull qwen3-embedding:latest`.

Usage:
    python ingest.py --data-dir ../data/entities --chroma-path ../chroma_db

The JSON files in --data-dir each contain a list of entity dicts.
Each entity is validated, embedded, and upserted into a single ChromaDB collection.
ChromaDB is the search index; canonical data stays in the JSON files.
"""
from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Iterable

import chromadb
import numpy as np
import ollama
from chromadb.config import Settings

# local import
sys.path.insert(0, str(Path(__file__).parent))
from schemas import BaseEntity, parse_entity

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("ingest")


# ---------------------------------------------------------------------------
# Loading + validation
# ---------------------------------------------------------------------------

def load_entities(data_dir: Path) -> list[BaseEntity]:
    """Read every *.json file in data_dir; each file is a list of entity dicts."""
    if not data_dir.exists():
        raise FileNotFoundError(f"Data dir not found: {data_dir}")

    entities: list[BaseEntity] = []
    seen_ids: set[str] = set()

    for fp in sorted(data_dir.glob("*.json")):
        log.info("Loading %s", fp.name)
        with fp.open("r", encoding="utf-8") as f:
            raw = json.load(f)

        if not isinstance(raw, list):
            raise ValueError(f"{fp.name}: top level must be a JSON array")

        for i, item in enumerate(raw):
            try:
                ent = parse_entity(item)
            except Exception as e:
                raise ValueError(f"{fp.name}[{i}]: validation failed: {e}") from e
            if ent.id in seen_ids:
                raise ValueError(f"Duplicate entity id across files: {ent.id}")
            seen_ids.add(ent.id)
            entities.append(ent)

    log.info("Loaded %d entities", len(entities))
    return entities


# ---------------------------------------------------------------------------
# Embedding text construction
# ---------------------------------------------------------------------------

def build_embedding_text(ent: BaseEntity) -> str:
    """
    Compose the string we hand to the embedder.

    Order matters: identity fields first so semantic similarity is biased
    toward the entity's identity, then keywords/tags for sparse-token recall,
    then full prose. Capped near typical model context limits.
    """
    parts = [
        f"{ent.type}: {ent.name}",
        ent.summary,
    ]
    if ent.keywords:
        parts.append("keywords: " + ", ".join(ent.keywords))
    if ent.tags:
        parts.append("tags: " + ", ".join(ent.tags))
    parts.append(ent.full_text)
    return "\n".join(p for p in parts if p)


# ---------------------------------------------------------------------------
# Metadata flattening for ChromaDB
# ---------------------------------------------------------------------------

def build_metadata(ent: BaseEntity) -> dict:
    """
    ChromaDB metadata values must be str|int|float|bool|None. No lists or dicts.
    Lists get joined into comma-separated strings (filterable by substring).
    """
    md: dict = {
        "entity_type": ent.type,
        "name": ent.name,
        "source_section": ent.source_section,
        "version": ent.version,
    }
    if ent.keywords:
        md["keywords"] = ",".join(ent.keywords)
    if ent.tags:
        md["tags"] = ",".join(ent.tags)

    # Type-specific filterable scalars
    data = ent.model_dump()
    for field in ("room_id", "level", "location_room_id", "dc", "value_gp",
                  "magical", "magic_item", "challenge_rating"):
        if field in data and data[field] not in (None, "", []):
            md[field] = data[field]

    # For monsters/npcs, surface CR from the nested stat block
    if ent.type in ("monster", "npc"):
        sb = data.get("stat_block")
        if sb and sb.get("challenge_rating"):
            md["challenge_rating"] = sb["challenge_rating"]
            md["xp"] = sb.get("xp", 0)
    return md


# ---------------------------------------------------------------------------
# Embedding model
# ---------------------------------------------------------------------------

def load_embedder(model_name: str, ollama_host: str) -> ollama.Client:
    """
    Connect to a running Ollama instance and verify the embedding model exists.

    Ollama runs as a separate process; this client just makes REST calls to
    /api/embed at the given host. Start the daemon with `ollama serve` and
    pull the model with `ollama pull qwen3-embedding:latest` before ingesting.
    """
    log.info("Connecting to Ollama at %s", ollama_host)
    client = ollama.Client(host=ollama_host)
    try:
        resp = client.list()
    except Exception as e:
        raise RuntimeError(
            f"Cannot reach Ollama at {ollama_host}. "
            f"Is `ollama serve` running? Underlying error: {e}"
        ) from e

    # ollama.list() returns a ListResponse with .models[*].model attribute
    available = [m.model for m in resp.models]
    if model_name not in available:
        log.warning(
            "Model %r not found in local Ollama registry. Available: %s. "
            "Attempting to use anyway; Ollama will pull or error.",
            model_name, available,
        )
    else:
        log.info("Model %r is available locally.", model_name)
    return client


def _l2_normalize(vectors: list[list[float]]) -> list[list[float]]:
    """L2-normalize so cosine similarity reduces to dot product in ChromaDB."""
    arr = np.array(vectors, dtype=np.float32)
    norms = np.linalg.norm(arr, axis=1, keepdims=True)
    norms = np.where(norms == 0.0, 1.0, norms)  # guard against zero vectors
    return (arr / norms).tolist()


def embed_documents(
    client: ollama.Client,
    model_name: str,
    texts: list[str],
    batch_size: int = 8,
) -> list[list[float]]:
    """
    Embed texts via Ollama's /api/embed endpoint, which supports batch input.
    L2-normalizes outputs since Ollama does not normalize by default and we
    want cosine similarity in ChromaDB.
    """
    log.info("Embedding %d documents in batches of %d", len(texts), batch_size)
    all_vectors: list[list[float]] = []
    n_batches = (len(texts) + batch_size - 1) // batch_size

    for i in range(0, len(texts), batch_size):
        batch = texts[i : i + batch_size]
        resp = client.embed(model=model_name, input=batch)
        batch_vecs = resp["embeddings"]
        if len(batch_vecs) != len(batch):
            raise RuntimeError(
                f"Ollama returned {len(batch_vecs)} embeddings for "
                f"{len(batch)} inputs; cannot align."
            )
        all_vectors.extend(batch_vecs)
        log.info("  batch %d/%d", (i // batch_size) + 1, n_batches)

    return _l2_normalize(all_vectors)


# ---------------------------------------------------------------------------
# ChromaDB
# ---------------------------------------------------------------------------

def get_collection(chroma_path: Path, collection_name: str):
    chroma_path.mkdir(parents=True, exist_ok=True)
    client = chromadb.PersistentClient(
        path=str(chroma_path),
        settings=Settings(anonymized_telemetry=False),
    )
    # Cosine distance (normalized embeddings -> cosine = dot product)
    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"},
    )
    return collection


def upsert_batch(
    collection,
    ids: list[str],
    embeddings: list[list[float]],
    documents: list[str],
    metadatas: list[dict],
) -> None:
    """Upsert is idempotent: re-running ingest with the same ids replaces vectors."""
    collection.upsert(
        ids=ids,
        embeddings=embeddings,
        documents=documents,
        metadatas=metadatas,
    )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def run(
    data_dir: Path,
    chroma_path: Path,
    collection_name: str,
    model_name: str,
    ollama_host: str,
    batch_size: int,
) -> None:
    entities = load_entities(data_dir)
    if not entities:
        log.warning("No entities to ingest. Exiting.")
        return

    client = load_embedder(model_name, ollama_host)
    embed_texts = [build_embedding_text(e) for e in entities]
    embeddings = embed_documents(client, model_name, embed_texts, batch_size)

    collection = get_collection(chroma_path, collection_name)

    ids = [e.id for e in entities]
    documents = [e.full_text for e in entities]
    metadatas = [build_metadata(e) for e in entities]

    upsert_batch(collection, ids, embeddings, documents, metadatas)

    log.info("Ingest complete. Collection '%s' now has %d entities.",
             collection_name, collection.count())

    # Summary by type
    counts: dict[str, int] = {}
    for e in entities:
        counts[e.type] = counts.get(e.type, 0) + 1
    log.info("Breakdown by type: %s", counts)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Ingest D&D entities into ChromaDB via Ollama")
    p.add_argument("--data-dir", type=Path, default=Path("/Users/nicholastristan_1/Apple Institute/Challenge 1 NLP/data/extracted"))
    p.add_argument("--chroma-path", type=Path, default=Path("../chroma_db"))
    p.add_argument("--collection-name", type=str, default="candlekeep_joy_extradimensional")
    p.add_argument("--model", type=str, default="qwen3-embedding:latest",
                   help="Ollama model tag, e.g. qwen3-embedding:latest")
    p.add_argument("--ollama-host", type=str, default="http://localhost:11434",
                   help="Ollama server URL")
    p.add_argument("--batch-size", type=int, default=8,
                   help="Embedding batch size; lower if VRAM is tight")
    return p.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run(
        args.data_dir,
        args.chroma_path,
        args.collection_name,
        args.model,
        args.ollama_host,
        args.batch_size,
    )
