"""
app.py -- Streamlit UI for the DM Assistant.

Run:
    cd dnd_rag/scripts
    streamlit run app.py

Two modes selectable in the sidebar:
  Live  -- instant fact lookup, no LLM, use at the table
  Prep  -- streaming LLM synthesis, use during session planning
"""
from __future__ import annotations

from pathlib import Path

import streamlit as st
import ollama

from query import (
    DEFAULT_CHAT_MODEL,
    DEFAULT_CHROMA_PATH,
    DEFAULT_COLLECTION,
    DEFAULT_EMBED_MODEL,
    DEFAULT_ENTITIES_DIR,
    DEFAULT_OLLAMA_HOST,
    get_collection,
    load_entity_store,
    query_live,
    query_prep_stream,
)

# ---------------------------------------------------------------------------
# Page config
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="DM Assistant",
    page_icon="📖",
    layout="centered",
)

# ---------------------------------------------------------------------------
# Cached resources (initialized once per session)
# ---------------------------------------------------------------------------

@st.cache_resource
def get_ollama_client(host: str) -> ollama.Client:
    return ollama.Client(host=host)


@st.cache_resource
def get_chroma_collection(chroma_path: str, collection_name: str):
    try:
        return get_collection(Path(chroma_path), collection_name)
    except Exception as e:
        return None


@st.cache_resource
def get_store(entities_dir: str) -> dict:
    return load_entity_store(Path(entities_dir))


# ---------------------------------------------------------------------------
# Sidebar — settings
# ---------------------------------------------------------------------------
with st.sidebar:
    st.header("Settings")

    mode = st.radio(
        "Mode",
        ["Live — fast facts", "Prep — deep synthesis"],
        help="Live: instant retrieval, no LLM. Prep: full reasoning with qwen2.5:14b.",
    )
    is_prep = mode.startswith("Prep")

    st.divider()

    with st.expander("Advanced", expanded=False):
        ollama_host = st.text_input("Ollama host", value=DEFAULT_OLLAMA_HOST)
        chroma_path = st.text_input("ChromaDB path", value=str(DEFAULT_CHROMA_PATH))
        entities_dir = st.text_input("Entities dir", value=str(DEFAULT_ENTITIES_DIR))
        collection_name = st.text_input("Collection", value=DEFAULT_COLLECTION)
        embed_model = st.text_input("Embed model", value=DEFAULT_EMBED_MODEL)
        chat_model = st.text_input("Chat model", value=DEFAULT_CHAT_MODEL)
        n_results = st.slider("Top-k results", min_value=1, max_value=15,
                              value=8 if is_prep else 3)

    st.divider()
    st.caption("The Joy of Extradimensional Spaces")
    st.caption("Candlekeep Mysteries, Ch. 1")

# ---------------------------------------------------------------------------
# Initialize resources
# ---------------------------------------------------------------------------
client = get_ollama_client(ollama_host)
collection = get_chroma_collection(chroma_path, collection_name)
store = get_store(entities_dir)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
st.title("DM Assistant")
st.caption(
    "**Live** — instant facts at the table  |  **Prep** — reasoning for session planning"
)

if collection is None:
    st.error(
        "ChromaDB collection not found. "
        "Run `python ingest.py` first, then refresh this page."
    )
    st.stop()

# Entity count badge
try:
    count = collection.count()
    st.info(f"{count} entities indexed", icon="📚")
except Exception:
    pass

st.divider()

# ---------------------------------------------------------------------------
# Chat history
# ---------------------------------------------------------------------------
if "messages" not in st.session_state:
    st.session_state.messages = []

# Render previous messages
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])
        if msg.get("sources"):
            with st.expander(f"Sources ({len(msg['sources'])})"):
                for s in msg["sources"]:
                    badge = s["entity_type"].upper()
                    dist = s.get("distance", 0)
                    st.markdown(f"**{s['name']}** `{badge}` — similarity: {1 - dist:.2f}")

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
placeholder = (
    "e.g. What is the DC to escape the bookshelf?"
    if not is_prep
    else "e.g. What if my party tries to burn the library?"
)

question = st.chat_input(placeholder)

if question:
    # Show user message
    with st.chat_message("user"):
        st.markdown(question)
    st.session_state.messages.append({"role": "user", "content": question})

    # Generate response
    with st.chat_message("assistant"):
        sources = []

        if not is_prep:
            # ── Live mode ──────────────────────────────────────────────
            with st.spinner("Searching..."):
                result = query_live(
                    question, collection, client, store,
                    embed_model=embed_model,
                    n_results=n_results,
                )
            answer = result["answer"]
            sources = result["entities"]
            st.markdown(answer)

        else:
            # ── Prep mode (streaming) ──────────────────────────────────
            try:
                token_gen, sources = query_prep_stream(
                    question, collection, client, store,
                    embed_model=embed_model,
                    chat_model=chat_model,
                    n_results=n_results,
                )
                answer = st.write_stream(token_gen)
            except Exception as e:
                answer = f"Generation error: {e}"
                st.error(answer)

        # Show sources
        if sources:
            with st.expander(f"Sources ({len(sources)})"):
                for s in sources:
                    badge = s["entity_type"].upper()
                    dist = s.get("distance", 0)
                    st.markdown(
                        f"**{s['name']}** `{badge}` — similarity: {1 - dist:.2f}"
                    )

    # Save to history
    st.session_state.messages.append({
        "role": "assistant",
        "content": answer,
        "sources": sources,
    })

# ---------------------------------------------------------------------------
# Footer actions
# ---------------------------------------------------------------------------
st.divider()
col1, col2 = st.columns(2)

with col1:
    if st.button("Clear chat history"):
        st.session_state.messages = []
        st.rerun()

with col2:
    if st.button("Reload entities + ChromaDB"):
        st.cache_resource.clear()
        st.rerun()