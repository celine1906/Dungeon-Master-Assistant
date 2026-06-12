# Candlelight DM - D&D Dungeon Master Assistant

A macOS application with RAG (Retrieval-Augmented Generation) capabilities to assist Dungeon Masters running **The Joy of Extradimensional Spaces** from Candlekeep Mysteries.

## Features

- **Intelligent Q&A**: Ask questions about NPCs, rooms, puzzles, and story elements
- **Interactive Mansion Map**: View labeled floor plan overlay during sessions
- **Scenario Generation**: Get multiple possible outcomes for player actions
- **Dual Mode Support**:
  - **Fast Mode**: Local Ollama (Qwen3-8b) for quick responses
  - **Smart Mode**: Groq API (Llama-3.3-70b) for detailed, complex scenarios
- **DM Read-Aloud Screen**: Story introduction before each session
- **Hybrid Retrieval**: BGE-M3 semantic search + BM25 keyword search with RRF fusion

## Architecture

```
┌─────────────────┐
│  Swift macOS    │
│   Frontend      │ ← User Interface
└────────┬────────┘
         │ HTTP
         ↓
┌─────────────────┐
│   FastAPI       │
│   Backend       │ ← REST API
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  RAG Pipeline   │
│  (pipeline.py)  │ ← Query routing, retrieval, generation
└────────┬────────┘
         │
    ┌────┴────┬──────────┐
    ↓         ↓          ↓
┌────────┐ ┌──────┐ ┌─────────┐
│ChromaDB│ │Ollama│ │Groq API │
│(BGE-M3)│ │Qwen3 │ │Llama-70b│
└────────┘ └──────┘ └─────────┘
```

## Setup

### Prerequisites

- macOS 13.0+
- Python 3.14+
- Xcode 15.0+
- [Ollama](https://ollama.ai) installed
- Groq API key (get from [console.groq.com](https://console.groq.com))

### Installation

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd "......"
   ```

2. **Set up Python environment**
   ```bash
   python3 -m venv nlpvenv
   source nlpvenv/bin/activate
   pip install -r requirements.txt
   ```

3. **Pull Ollama models**
   ```bash
   ollama pull bge-m3
   ollama pull qwen3:8b-q4_K_M
   ```

4. **Configure API key**
   ```bash
   echo 'API_KEY="your-groq-api-key-here"' > .env
   ```

5. **Start the backend server**
   ```bash
   chmod +x start_server.sh
   ./start_server.sh
   ```
   Or manually:
   ```bash
   source nlpvenv/bin/activate
   uvicorn main:app --host 127.0.0.1 --port 8000 --reload
   ```

6. **Open the macOS app**
   - Open `DungeonAssistantAPP/DungeonAssistantAPP.xcodeproj` in Xcode
   - Build and run (⌘R)

## Project Structure

```
.
├── DungeonAssistantAPP/          # Swift macOS app
│   ├── DungeonAssistantAPP/      # Main app code
│   │   ├── Views/                # UI components
│   │   ├── Models/               # Data models
│   │   ├── RAGClient.swift       # API client
│   │   └── ServerManager.swift   # Server lifecycle
│   └── DungeonAssistantAPP.xcodeproj
│
├── main.py                       # FastAPI server
├── pipeline.py                   # RAG pipeline (retrieval + generation)
├── requirements.txt              # Python dependencies
│
├── data/                         # Extracted entities
│   ├── entities/                 # NPCs, monsters, items, etc.
│   └── extracted/               # Raw extracted data
│
├── vectordb/                     # ChromaDB vector database
├── chapter1_v8_chunks (1).jsonl # Text chunks for RAG
├── TheJoyExtradimensionalSpaces.pdf # Source adventure
│
├── scripts/                      # Utility scripts
│   ├── ingest.py                # Data ingestion
│   └── query.py                 # Query testing
│
└── templates/                    # Prompt templates
```

## Usage

### Starting the App

1. The app auto-starts the Python server on launch
2. Wait for "Connected" status in the top bar
3. Select "Chapter 1: The Joy of Extradimensional Spaces"
4. Read the DM intro screen (or skip)
5. Start asking questions!

### Query Examples

**Room Information:**
- "What's in room M1?"
- "Describe the library"

**NPC Questions:**
- "Who is Matreous?"
- "Tell me about Fistandia"

**Action Scenarios:**
- "The players attack the gingerbread golems, what should I do?"
- "What happens if they open the puzzle book without solving it?"

**Knowledge Questions:**
- "What are all the puzzle books?"
- "How do the players escape the mansion?"

### Mode Toggle

Switch between modes in the chat interface:
- **Low Mode (Ollama/Qwen3)**: Fast, concise answers
- **Smart Mode (Groq/Llama-70b)**: Detailed scenarios with multiple options

### Mansion Map

Click the **?** icon in the top-right corner to view the labeled mansion floor plan.

## Key Technologies

- **Frontend**: SwiftUI (macOS)
- **Backend**: FastAPI (Python)
- **Vector DB**: ChromaDB
- **Embeddings**: BGE-M3 (1024-dim)
- **LLMs**:
  - Local: Ollama Qwen3-8b (quantized)
  - Cloud: Groq Llama-3.3-70b
- **Retrieval**: Hybrid (dense + sparse) with RRF fusion

## Configuration

### Query Routing Profiles

The pipeline automatically detects query types and adjusts retrieval:

| Query Type | Dense Weight | Sparse Weight | Context Tokens |
|-----------|-------------|---------------|----------------|
| Room Code (M1, M2, etc.) | 0.3 | 0.7 | 1024 |
| Action/Scenario | 0.5 | 0.5 | 1500 |
| Knowledge | 0.7 | 0.3 | 1500 |

### Customizing Prompts

Edit prompts in `pipeline.py`:
- `SYSTEM_PROMPT` - Base instructions for the LLM
- `SMART_SYSTEM_PROMPT` - Enhanced prompt for Groq mode

## Troubleshooting

### Server won't start
- Check if port 8000 is already in use: `lsof -i :8000`
- Kill existing processes: `pkill -f uvicorn`
- Verify Python environment is activated

### "Operation not permitted" error
- Disable App Sandbox in `D_D_DM_s_Assistant.entitlements`
- Clean build folder in Xcode (⌘⇧K)
- Rebuild project

### Empty responses
- Check Ollama is running: `ollama list`
- Verify embeddings model: `ollama pull bge-m3`
- Check server logs for errors

### ChromaDB errors
- Delete and regenerate vector DB:
  ```bash
  rm -rf vectordb/
  python scripts/ingest.py
  ```

## Development

### Adding New Chapters

1. Extract text into JSONL chunks
2. Update `Chapter.all` in `Models.swift`
3. Add chapter data to vector DB
4. Create new intro sections in `ChapterIntroView.swift`

### Modifying Retrieval

Edit `pipeline.py`:
- `estimate_query_type()` - Query classification logic
- `RETRIEVAL_PROFILES` - Weights and context sizes
- `generate_answer()` - Core RAG logic

## Credits

Built for Candlekeep Mysteries by Wizards of the Coast.

