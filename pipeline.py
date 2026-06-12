# pipeline.py
import json, re
import numpy as np
import chromadb
import ollama
from rank_bm25 import BM25Okapi
from pathlib import Path
from collections import Counter
from ollama import chat
import os
from dotenv import load_dotenv
from groq import Groq

# Load environment variables
load_dotenv()

# ── Config ──────────────────────────────────────────────────────────────
CHROMA_PATH      = Path("chroma_db_final")
COLLECTION_NAME  = "candlekeep_final"
EMBEDDING_MODEL  = "bge-m3:latest"
OLLAMA_HOST      = "http://localhost:11434"

# Initialize Groq client
GROQ_API_KEY = os.getenv("API_KEY")
groq_client = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None

# ── Init clients (dijalankan sekali saat startup) ────────────────────────
ollama_client  = ollama.Client(host=OLLAMA_HOST)
chroma_client  = chromadb.PersistentClient(path=str(CHROMA_PATH))
collection     = chroma_client.get_or_create_collection(
    name=COLLECTION_NAME,
    metadata={"hnsw:space": "cosine"}
)

# ── Load all_chunks + BM25 corpus (sekali saat startup) ─────────────────
# Load all chunks should be from the same DB where the vectors is stored
JSONL_PATH = Path("chapter1_v8_chunks (1).jsonl")

all_chunks = []
with open(JSONL_PATH, "r", encoding="utf-8") as f:
    for line in f:
        if line.strip():
            all_chunks.append(json.loads(line))

def build_embedding_text(chunk):
    parts = []

    # Type and title
    parts.append(f"{chunk['type']}: {chunk['title']}")

    # Hiearchy level
    parts.append(f"depth {chunk['depth']}")

    # Source Section
    if chunk.get('summary'):
        parts.append(f"summary: {chunk['summary']}")

    # Keywords
    if chunk.get('keywords'):
        kw = ", ".join(chunk['keywords'])
        parts.append(f"keywords: {kw}")
    
    # Tags (for keyword/topic recall)
    if chunk.get('tags'):
        tags_str = ", ".join(chunk['tags'])
        parts.append(f"tags: {tags_str}")

    # Entities (NPCs, monsters, items, locations, etc.)
    if chunk.get('entities'):
        entities = chunk['entities']
        entity_parts = []
        for entity_type, entity_list in entities.items():
            if entity_list:
                entity_parts.append(f"{entity_type}: {', '.join(entity_list[:5])}")
        if entity_parts:
            parts.append("entities: " + "; ".join(entity_parts))

    # Full text
    if chunk.get('full_text') and chunk['full_text'].strip():
        parts.append(chunk['full_text'])

    # Join all parts with newlines
    return "\n".join(parts)

embedding_texts = [build_embedding_text(c) for c in all_chunks]

def tokenize(text):
    return re.findall(r'\w+', text.lower())

corpus            = [tokenize(doc) for doc in embedding_texts]
bm25              = BM25Okapi(corpus)
chunk_id_mapping  = {i: chunk["id"] for i, chunk in enumerate(all_chunks)}
chunk_by_id       = {chunk["id"]: chunk for chunk in all_chunks}

# ── Fungsi-fungsi dari notebook (copy persis) ────────────────────────────
def l2_normalize(vectors):
    arr = np.array(vectors, dtype = np.float32)
    norms = np.linalg.norm(arr, axis=1, keepdims=True)
    norms = np.where(norms == 0.0, 1.0, norms)
    return (arr / norms).tolist()

def dense_retrieve(query_text, n_results=20):
    # Embed the query
    query_response = ollama_client.embed(
        model=EMBEDDING_MODEL,
        input=[query_text]
    )

    query_embedding = query_response["embeddings"][0]

    # L2 normalize
    import numpy as np
    query_embedding = np.array(query_embedding, dtype=np.float32)
    query_embedding = query_embedding / np.linalg.norm(query_embedding)
    query_embedding = query_embedding.tolist()

    # Query ChromaDB
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        include=["metadatas", "distances"]
    )

    # Convert to (chunk_id, score) tuples
    dense_results = []
    for meta, distance in zip(results["metadatas"][0], results["distances"][0]):
        chunk_id = meta["chunk_id"]
        similarity = 1 - distance
        dense_results.append((chunk_id, similarity))

    return dense_results

def sparse_retrieve(query_text, n_results=20):
    # Tokenize query
    query_tokens = tokenize(query_text)

    # Get BM25 scores for all documents
    scores = bm25.get_scores(query_tokens)

    # Get top N indices sorted by score
    top_indices = sorted(
        range(len(scores)),
        key=lambda i: scores[i],
        reverse=True
    )[:n_results]

    # Convert to (chunk_id, score) tuples
    sparse_results = []
    for idx in top_indices:
        chunk_id = chunk_id_mapping[idx]
        score = scores[idx]
        sparse_results.append((chunk_id, score))

    return sparse_results

def weighted_rff(dense_results, sparse_results, k=60, dense_weight = 0.6, sparse_weight = 0.4):

    rrf_scores = {}

    # Process dense results with weight
    for rank, (chunk_id, _) in enumerate(dense_results, start=1):
        rrf_scores[chunk_id] = rrf_scores.get(chunk_id, 0) + (dense_weight / (k + rank))

    # Process sparse results with weight
    for rank, (chunk_id, _) in enumerate(sparse_results, start=1):
        rrf_scores[chunk_id] = rrf_scores.get(chunk_id, 0) + (sparse_weight / (k + rank))

    # Sort by weighted RRF score
    fused_results = sorted(
        rrf_scores.items(),
        key=lambda x: x[1],
        reverse=True
    )
    
    return fused_results

def hybrid_query(query_text, n_results=3, over_retrieve=20, dense_weight=0.6, sparse_weight=0.4):
    """
    Hybrid retrieval: Dense + Sparse + Weighted RRF fusion.
    
    Args:
        query_text: Natural language query
        n_results: Final number of results to return
        over_retrieve: How many results to get from each method before fusion
        dense_weight: Weight for dense retrieval (default 0.6)
        sparse_weight: Weight for sparse retrieval (default 0.4)
    
    Returns:
        List of dicts with chunk data and scores
    """
    print(f"Query: '{query_text}'")
    print(f"Weights: Dense={dense_weight}, Sparse={sparse_weight}\n")

    # Step 1: Dense retrieval
    print(f"Dense retrieval (top {over_retrieve})...")
    dense_results = dense_retrieve(query_text, n_results=over_retrieve)

    # Step 2: Sparse retrieval
    print(f"Sparse retrieval (top {over_retrieve})...")
    sparse_results = sparse_retrieve(query_text, n_results=over_retrieve)

    # Step 3: Weighted RRF fusion
    print(f"Weighted RRF fusion : ")
    fused_results = weighted_rff(dense_results, sparse_results,
                                    dense_weight=dense_weight, sparse_weight=sparse_weight)

    # Take top N
    top_n = fused_results[:n_results]

    # Hydrate with full chunk data
    results = []
    for chunk_id, rrf_score in top_n:
        chunk = next(c for c in all_chunks if c["id"] == chunk_id)

        # Find original scores from dense/sparse
        dense_score = next((s for cid, s in dense_results if cid == chunk_id), 0)
        sparse_score = next((s for cid, s in sparse_results if cid == chunk_id), 0)

        results.append({
            "chunk_id": chunk_id,
            "chunk": chunk,
            "rrf_score": rrf_score,
            "dense_score": dense_score,
            "sparse_score": sparse_score
        })

    print(f"Retrieved {len(results)} results\n")
    return results

def build_context(ranked_results: list, max_chunks: int = 3) -> str:
    """
    Ubah hasil hybrid_query() menjadi context string untuk prompt.
    ranked_results: output dari hybrid_query() — list of dicts with 'chunk' key.
    """
    parts = []
    for i, result in enumerate(ranked_results[:max_chunks], 1):
        chunk = result["chunk"]
        title = chunk.get("title", "Untitled")
        ctype = chunk.get("type", "unknown")
        full_text = chunk.get("full_text", "").strip()
        summary = chunk.get("summary", "").strip()

        # Gunakan full_text kalau ada, fallback ke summary
        body = full_text if full_text else summary

        parts.append(
            f"[{i}] ({ctype}) {title}\n{body}"
        )

    return "\n\n---\n\n".join(parts)

# ── Query Type Detection & Retrieval Profiles ──────────────────────────
def estimate_query_type(query: str) -> str:
    """Estimate if query is about room codes, actions, or knowledge"""
    q = query.lower()
    if re.search(r"\bm\d+\b", q):
        return "room_code"

    action_signals = [
        "player", "players", "party",
        "what should", "what happens", "what if",
        "how do i", "how should",
        "tries to", "try to", "attempt",
        "want to", "attack", "burn", "open",
    ]
    if any(s in q for s in action_signals):
        return "action"

    return "knowledge"

RETRIEVAL_PROFILES = {
    "room_code":  {"dense": 0.3, "sparse": 0.7, "num_predict": 1024, "num_ctx": 1024},
    "action":     {"dense": 0.5, "sparse": 0.5, "num_predict": 1500, "num_ctx": 1500},
    "knowledge":  {"dense": 0.7, "sparse": 0.3, "num_predict": 1024, "num_ctx": 1500},  # Increased from 512
}

def retrieve_and_rerank(query: str, k_fetch: int = 20, k_final: int = 3) -> list:
    return hybrid_query(
        query_text=query,
        n_results=k_final,
        over_retrieve=k_fetch,
        dense_weight=0.6,
        sparse_weight=0.4
    )

SYSTEM_PROMPT = """You are a JSON-only API for a D&D 5e adventure assistant.

CRITICAL RULES:
- Return ONLY raw JSON - no markdown, no explanations, no preamble
- Do NOT use ** for bold or any markdown formatting
- Do NOT add "Final Answer" or any headers
- The first character must be { and last character must be }
- Use ONLY retrieved context
- Never reveal hidden information

Your entire response must be valid, parseable JSON."""

USER_PROMPT_TEMPLATE = """CONTEXT:
{context}

QUESTION:
{query}

Do NOT generate scenarios. Answer the question directly.

IMPORTANT: You MUST include the "source_chunks" field as an empty array.

If the answer is in context, return:
{{
    "response_type": "answer",
    "answer": "string (2-3 sentences max)",
    "canonical": true,
    "source_chunks": []
}}

If NOT in context, return:
{{
    "response_type": "answer",
    "answer": "No information available. Please ask questions about DnD",
    "canonical": false,
    "source_chunks": []
}}"""

SCENARIO_USER_TEMPLATE = """CONTEXT:
{context}

PLAYER ACTION:
{query}

Generate exactly 3 possible next scenarios based on context.
At least one must be canonical. Improvised scenarios must fit the adventure tone and supports main plot progression.

CRITICAL RULES:
- Your ENTIRE response must be ONLY the JSON object below
- Do NOT add any text before or after the JSON
- Do NOT use markdown formatting (no **, no #, no headers)
- ALL fields are REQUIRED
- "consequences" MUST be an array of strings (use ["N/A"] if unknown)
- "source_chunks" MUST be an array of strings (use ["N/A"] if unknown)
- "location" must be a string (use "N/A" if unknown)

Return ONLY this JSON structure (no other text):
{{
    "response_type": "scenario",
    "scenarios": [
        {{
            "title": "descriptive scenario title",
            "type": "Exploration | Investigation | Social | Combat | Puzzle | Discovery",
            "location": "location name or N/A",
            "description": "one sentence description",
            "consequences": ["consequence 1", "consequence 2"],
            "canonical": true,
            "source_chunks": ["chunk reference or N/A"]
        }},
        {{
            "title": "second scenario title",
            "type": "Combat",
            "location": "location or N/A",
            "description": "description",
            "consequences": ["consequence 1", "consequence 2"],
            "canonical": false,
            "source_chunks": ["chunk reference or N/A"]
        }},
        {{
            "title": "third scenario title",
            "type": "Discovery",
            "location": "N/A",
            "description": "description",
            "consequences": ["consequence 1", "consequence 2"],
            "canonical": false,
            "source_chunks": ["chunk reference or N/A"]
        }}
    ]
}}"""

# ── Enhanced Prompts for Groq (Complex Mode) ────────────────────────────
GROQ_KNOWLEDGE_TEMPLATE = """CONTEXT:
{context}

QUESTION:
{query}

As an expert D&D 5e Dungeon Master assistant, provide a comprehensive, detailed answer based ONLY on the context.

Include:
- Direct answer (2-4 sentences)
- Relevant lore and backstory when available
- Character motivations or plot connections
- Potential story hooks or complications
- Mechanical details (stats, DCs, damage) if applicable

IMPORTANT: You MUST include the "source_chunks" field as an empty array.

If the answer is in context, return:
{{
    "response_type": "answer",
    "answer": "comprehensive answer with lore, motivations, and plot hooks (2-4 sentences)",
    "canonical": true,
    "source_chunks": []
}}

If NOT in context, return:
{{
    "response_type": "answer",
    "answer": "No information available. Please ask questions about D&D content from the adventure.",
    "canonical": false,
    "source_chunks": []
}}

CRITICAL RULES:
- Return ONLY raw JSON - no markdown, no explanations, no preamble
- Do NOT use ** for bold or any markdown formatting
- Do NOT add "Final Answer" or any headers
- The first character must be {{ and last character must be }}"""

GROQ_SCENARIO_TEMPLATE = """CONTEXT:
{context}

PLAYER ACTION:
{query}

As an expert D&D 5e Dungeon Master, generate exactly 3 richly detailed possible scenarios.

For EACH scenario, provide:
- Vivid environmental descriptions (lighting, sounds, smells, atmosphere)
- NPC reactions with dialogue or body language
- Specific skill check DCs with mechanical justification (e.g., "DC 15 Perception to notice hidden switch due to darkness")
- Multiple consequences (immediate + long-term plot effects)
- Alternative approaches players might take

At least one scenario MUST be canonical (directly from context).
Improvised scenarios must fit the adventure's tone and advance the main plot.

Return ONLY this JSON structure:
{{
    "response_type": "scenario",
    "scenarios": [
        {{
            "title": "engaging scenario title",
            "type": "Exploration | Investigation | Social | Combat | Puzzle | Discovery",
            "location": "specific location name",
            "description": "rich 2-3 sentence description with environmental details, NPC reactions, and atmosphere",
            "consequences": ["immediate consequence", "long-term plot effect", "alternative outcome"],
            "canonical": true,
            "source_chunks": ["relevant chunk reference"]
        }},
        {{
            "title": "second scenario title",
            "type": "type",
            "location": "location",
            "description": "detailed description with skill DCs and mechanical effects",
            "consequences": ["consequence 1", "consequence 2", "consequence 3"],
            "canonical": false,
            "source_chunks": ["N/A"]
        }},
        {{
            "title": "third scenario title",
            "type": "type",
            "location": "location",
            "description": "vivid description with dialogue or sensory details",
            "consequences": ["consequence 1", "consequence 2", "consequence 3"],
            "canonical": false,
            "source_chunks": ["N/A"]
        }}
    ]
}}

CRITICAL RULES:
- Your ENTIRE response must be ONLY the JSON object
- Do NOT add any text before or after the JSON
- Do NOT use markdown formatting (no **, no #, no headers)
- ALL fields are REQUIRED
- "consequences" MUST be an array with at least 2-3 strings
- The first character must be {{ and last character must be }}"""

def generate_answer(query: str, k_fetch: int = 20, k_final: int = 3, mode: str = "fast") -> str:
    """
    Full RAG pipeline with dynamic query routing and mode selection:
      1. Detect query type (room_code/action/knowledge)
      2. Apply optimal retrieval weights
      3. Retrieve & rerank
      4. Generate with mode-specific settings

    Args:
        query: User's natural language query
        k_fetch: Number of chunks to retrieve before reranking
        k_final: Final number of chunks to use for context
        mode: "fast" (Ollama/Qwen3) or "smart" (Groq/Llama3-70b)

    Returns:
        JSON string with answer or scenarios
    """
    # Detect query type and get profile
    qtype = estimate_query_type(query)
    profile = RETRIEVAL_PROFILES[qtype]

    print(f"[DEBUG] Query type: {qtype}")
    print(f"[DEBUG] Mode: {mode}")
    print(f"[DEBUG] Profile: dense={profile['dense']}, sparse={profile['sparse']}, num_predict={profile['num_predict']}")

    # Retrieve with dynamic weights
    ranked = hybrid_query(
        query_text=query,
        n_results=k_final,
        over_retrieve=k_fetch,
        dense_weight=profile["dense"],
        sparse_weight=profile["sparse"],
    )

    context = build_context(ranked, max_chunks=k_final)

    # Route to appropriate mode
    if mode == "smart":
        # Use Groq with complex prompts
        if not groq_client:
            raise ValueError("Groq API key not configured. Set API_KEY in .env file.")

        # Pick template based on query type (complex prompts for Groq)
        if qtype in ("action", "room_code"):
            user_prompt = GROQ_SCENARIO_TEMPLATE.format(context=context, query=query)
        else:  # "knowledge"
            user_prompt = GROQ_KNOWLEDGE_TEMPLATE.format(context=context, query=query)

        # Call Groq API
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user",   "content": user_prompt},
            ],
            temperature=0.1,
            max_tokens=profile["num_predict"],
        )

        return clean_json_output(response.choices[0].message.content)

    else:  # mode == "fast" (default)
        # Use Ollama with simple prompts
        # Pick template based on query type
        if qtype in ("action", "room_code"):
            user_prompt = SCENARIO_USER_TEMPLATE.format(context=context, query=query)
        else:  # "knowledge"
            user_prompt = USER_PROMPT_TEMPLATE.format(context=context, query=query)

        # Use optimized model and settings from profile
        full_response = []
        for chunk in chat(
            model="qwen3:8b-q4_K_M",  # Quantized model for speed
            options={
                "temperature": 0.1,  # Lower temperature for consistency
                "num_predict": profile["num_predict"],  # Dynamic token limit
                "num_ctx": profile["num_ctx"],  # Dynamic context window
                "think": False
            },
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user",   "content": user_prompt}
            ],
            stream=True
        ):
            full_response.append(chunk["message"]["content"])

        cleaned = clean_json_output("".join(full_response))
        return cleaned



def clean_json_output(text: str) -> str:
    """Clean and extract valid JSON from LLM output"""
    # Remove markdown formatting
    text = re.sub(r'\*\*[^*]+\*\*', '', text)  # Remove **bold**
    text = re.sub(r'\*[^*]+\*', '', text)      # Remove *italic*

    # Find JSON object boundaries
    first_brace = text.find('{')
    last_brace = text.rfind('}')

    if first_brace != -1 and last_brace != -1:
        text = text[first_brace:last_brace + 1]

    # Clean up malformed quotes
    text = re.sub(r'([{,]\s*)"(\s*)"', r'\1"', text)
    text = re.sub(r'"\s+(\w)', r'"\1', text)

    return text.strip()


# ==============================================================
# ANSWER GENERATION USING GROQ API (LLAMA3.3-70B-VERSATILE)
# ==============================================================





def generate_answer_api(query: str) -> str:
    qtype = estimate_query_type(query)
    p = RETRIEVAL_PROFILES[qtype]

    ranked = hybrid_query(
        query_text=query,
        n_results=5,
        over_retrieve=20,
        dense_weight=p["dense"],
        sparse_weight=p["sparse"],
    )
    context = build_context(ranked)

    if qtype == "action":
        user_prompt = SCENARIO_USER_TEMPLATE.format(context=context, query=query)
    else:
        user_prompt = USER_PROMPT_TEMPLATE.format(context=context, query=query)

    response = groq_client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user",   "content": user_prompt},
        ],
        temperature=0.1,
        max_tokens=p["num_predict"],
    )

    return response.choices[0].message.content