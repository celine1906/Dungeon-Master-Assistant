"""
Test script: Extract queries from rag_retrieval_evaluation.ipynb and test in rag_pipeline.ipynb
Displays read-aloud text and source information from JSON entities.

Run this in a Jupyter notebook cell or as standalone script.
"""

import json
import sys
from pathlib import Path
from typing import List, Dict, Any
import chromadb
import numpy as np
import ollama
from chromadb.config import Settings

# ============================================================================
# STEP 1: Extract all 25 queries from test_cases
# ============================================================================

TEST_QUERIES = [
    "What monsters might attack the party?",
    "Who can I talk to in this adventure?",
    "What valuable items can I find?",
    "Tell me about the adventure",
    "What clue can help solve the mystery?",
    "What is described in the book?",
    "How does the portal open?",
    "What are the puzzle books?",
    "What is the imp figurine?",
    "How do characters assemble the books?",
    "What is the conclusion of the adventure?",
    "What further adventures are suggested?",
    "Who is Matreous and where is he?",
    "What is Fistandia known for?",
    "Who are Cumin and Coriander?",
    "What is in the foyer and hallway?",
    "What creatures guard the library?",
    "What happens in the exercise room?",
    "What is in the study?",
    "What food or supplies are in the kitchen?",
    "What is stored in the pantry?",
    "What is in the dining room?",
    "What plants or animals are in the arboretum?",
    "What equipment is in the laboratory?",
    "What is inside the planetarium?",
]

print(f"Extracted {len(TEST_QUERIES)} test queries")


# ============================================================================
# STEP 2: Setup - Connect to ChromaDB and load entity JSON files
# ============================================================================

# Configuration
SCRIPT_DIR = Path(__file__).parent.absolute()  # Get script directory
CHROMA_PATH = SCRIPT_DIR / "chroma_db"
COLLECTION_NAME = "candlekeep_joy_extradimensional"
EMBEDDING_MODEL = "qwen3-embedding:latest"
OLLAMA_HOST = "http://localhost:11434"
DATA_DIR = SCRIPT_DIR / "data" / "extracted"  # Where original JSON entities are stored

# Connect to ChromaDB
print(f"Connecting to ChromaDB at: {CHROMA_PATH}")
chroma_client = chromadb.PersistentClient(
    path=str(CHROMA_PATH),
    settings=Settings(anonymized_telemetry=False),
)

# List available collections
available_collections = chroma_client.list_collections()
print(f"Available collections: {[c.name for c in available_collections]}")

# Get collection
collection = chroma_client.get_collection(name=COLLECTION_NAME)
ollama_client = ollama.Client(host=OLLAMA_HOST)

print(f"✅ Connected to ChromaDB collection: {COLLECTION_NAME}")
print(f"Total entities: {collection.count()}")


# Load all JSON entities into a lookup dictionary
def load_all_entities(data_dir: Path) -> Dict[str, Dict]:
    """Load all entities from JSON files into a dict keyed by entity ID."""
    entities_by_id = {}

    for json_file in data_dir.glob("*.json"):
        with json_file.open("r", encoding="utf-8") as f:
            data = json.load(f)

        if isinstance(data, list):
            for entity in data:
                entity_id = entity.get("id")
                if entity_id:
                    entities_by_id[entity_id] = entity

    return entities_by_id


entities_lookup = load_all_entities(DATA_DIR)
print(f"✅ Loaded {len(entities_lookup)} entities from JSON files")


# ============================================================================
# STEP 3: Query function with enhanced display
# ============================================================================

def query_with_sources(query_text: str, n_results: int = 5):
    """
    Query RAG pipeline and display results with:
    - Read-aloud text (if available)
    - Source information from JSON entities
    """
    # Embed query
    query_embedding = ollama_client.embed(model=EMBEDDING_MODEL, input=[query_text])
    query_vector = query_embedding["embeddings"][0]
    query_vector = (np.array(query_vector) / np.linalg.norm(query_vector)).tolist()

    # Query ChromaDB
    results = collection.query(
        query_embeddings=[query_vector],
        n_results=n_results,
        include=["documents", "metadatas", "distances"]
    )

    # Display results
    print(f"\n{'='*80}")
    print(f"QUERY: {query_text}")
    print(f"{'='*80}\n")

    if not results['ids'][0]:
        print("❌ No results found")
        return

    for i, (doc_id, metadata, document, distance) in enumerate(zip(
        results['ids'][0],
        results['metadatas'][0],
        results['documents'][0],
        results['distances'][0]
    ), start=1):

        similarity = 1 - distance
        entity_type = metadata.get('entity_type', 'unknown')
        name = metadata.get('name', 'Unknown')
        source_section = metadata.get('source_section', 'N/A')

        print(f"Result {i}: {name}")
        print(f"{'-'*80}")
        print(f"  Type: {entity_type}")
        print(f"  Similarity: {similarity:.4f}")
        print(f"  Source: {source_section}")

        # Get full entity from JSON
        full_entity = entities_lookup.get(doc_id)

        if full_entity:
            # Show read-aloud text if it's a room (FULL TEXT - NO TRUNCATION)
            if entity_type == "room" and "read_aloud_text" in full_entity:
                read_aloud = full_entity["read_aloud_text"]
                print(f"\n  📖 READ ALOUD TEXT:")
                print(f"  {read_aloud}")  # ← REMOVED [:300] truncation

            # Show keywords and tags (ALL keywords/tags)
            if "keywords" in full_entity:
                keywords = full_entity.get("keywords", [])
                print(f"\n  🔑 Keywords: {', '.join(keywords)}")  # ← REMOVED [:5] limit

            if "tags" in full_entity:
                tags = full_entity.get("tags", [])
                print(f"  🏷️  Tags: {', '.join(tags)}")  # ← REMOVED [:5] limit

            # Show summary (FULL SUMMARY - NO TRUNCATION)
            if "summary" in full_entity:
                summary = full_entity["summary"]
                print(f"\n  📝 Summary: {summary}")  # ← REMOVED [:200] truncation

            # Room-specific: connected rooms (ALL connected rooms)
            if entity_type == "room" and "connected_rooms" in full_entity:
                connected = full_entity["connected_rooms"]
                if connected:
                    print(f"\n  🚪 Connected to: {', '.join(connected)}")  # ← REMOVED [:3] limit

            # Monster/NPC-specific: stats
            if entity_type in ["monster", "npc"] and "challenge_rating" in metadata:
                cr = metadata["challenge_rating"]
                print(f"\n  ⚔️  Challenge Rating: {cr}")

            # Treasure/Item-specific: value
            if entity_type in ["treasure", "item"]:
                if "value_gp" in metadata:
                    value = metadata["value_gp"]
                    print(f"\n  💰 Value: {value} gp")
                if "magical" in metadata:
                    magical = metadata["magical"]
                    print(f"  ✨ Magical: {magical}")

        else:
            print(f"\n  ⚠️  Full entity not found in JSON files")

        print()

    print(f"{'='*80}\n")


# ============================================================================
# STEP 4: Run all 25 test queries
# ============================================================================

def test_all_queries():
    """Run all test queries and display results."""
    print("\n" + "="*80)
    print(" "*20 + "TESTING 25 QUERIES FROM EVALUATION")
    print("="*80 + "\n")

    for i, query in enumerate(TEST_QUERIES, start=1):
        print(f"\n[Query {i}/{len(TEST_QUERIES)}]")
        query_with_sources(query, n_results=3)  # Show top 3 results

        # Optional: pause between queries
        # input("Press Enter to continue...")

    print("\n" + "="*80)
    print("✅ Completed testing all 25 queries")
    print("="*80)


# ============================================================================
# USAGE
# ============================================================================

if __name__ == "__main__":
    # Test a single query
    print("\n🔍 EXAMPLE: Testing single query\n")
    query_with_sources("What monsters might attack the party?", n_results=5)

    # Uncomment to test all 25 queries
    # test_all_queries()
