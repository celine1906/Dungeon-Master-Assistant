# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pipeline import generate_answer, retrieve_and_rerank, build_context

app = FastAPI(title="DnD RAG API")

# Izinkan request dari Swift app (atau semua origin untuk dev)
# Receive query request 
# Calls pipeline.generate (pipeline.py)
# Penghubung utama dari swift(Mac OS App) ke pipeline (MAIN RAG)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class QueryRequest(BaseModel):
    query: str
    k_fetch: int = 20
    k_final: int = 5
    mode: str = "fast"  # "fast" (Ollama/Qwen3) or "smart" (Groq/Llama3-70b)

class QueryResponse(BaseModel):
    answer: str   # raw JSON string from LLM

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/query", response_model=QueryResponse)
def query_endpoint(req: QueryRequest):
    try:
        answer = generate_answer(
            req.query,
            k_fetch=req.k_fetch,
            k_final=req.k_final,
            mode=req.mode
        )
        return QueryResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))