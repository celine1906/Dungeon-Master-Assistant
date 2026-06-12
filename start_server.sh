#!/bin/bash

# D&D DM Assistant Server Startup Script

echo "🎲 Starting D&D DM Assistant Server..."
echo ""

# Activate virtual environment
if [ -d "nlpvenv" ]; then
    echo "Activating virtual environment..."
    source nlpvenv/bin/activate
    echo "✓ Virtual environment activated"
else
    echo "⚠️  Warning: Virtual environment not found, using system Python"
fi
echo ""

# Check if Ollama is running
echo "Checking Ollama..."
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "❌ Ollama is not running!"
    echo "Please start Ollama first:"
    echo "  1. Open Ollama application"
    echo "  2. Or run: ollama serve"
    exit 1
fi
echo "✓ Ollama is running"

# Check if required model is available
echo "Checking for bge-m3 model..."
if ! ollama list | grep -q "bge-m3"; then
    echo "❌ bge-m3 model not found!"
    echo "Please pull the model first:"
    echo "  ollama pull bge-m3:latest"
    exit 12
fi
echo "✓ bge-m3 model is available"

# Check if qwen3 model is available
echo "Checking for qwen3 model..."
if ! ollama list | grep -q "qwen3"; then
    echo "❌ qwen3 model not found!"
    echo "Please pull the model first:"
    echo "  ollama pull qwen3:8b-q4_K_M"
    exit 1
fi
echo "✓ qwen3 model is available"

# Check if ChromaDB exists
if [ ! -d "chroma_db_final" ]; then
    echo "❌ ChromaDB not found at chroma_db_final/"
    echo "Please run your embedding notebook first to create the database"
    exit 1
fi
echo "✓ ChromaDB found"

# Check if JSONL file exists
if [ ! -f "chapter1_v8_chunks (1).jsonl" ]; then
    echo "❌ Data file not found: chapter1_v8_chunks (1).jsonl"
    exit 1
fi
echo "✓ Data file found"

echo ""
echo "🚀 Starting FastAPI server..."
echo "================================================"
echo "Server URL: http://127.0.0.1:8000"
echo ""
echo "API Endpoints:"
echo "  GET  http://127.0.0.1:8000/health       - Health check"
echo "  POST http://127.0.0.1:8000/query        - Query endpoint"
echo "  GET  http://127.0.0.1:8000/docs         - API documentation"
echo ""
echo "Your Swift app should connect to:"
echo "  http://127.0.0.1:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo "================================================"
echo ""

# Start the server using uvicorn (FastAPI requires uvicorn)
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
