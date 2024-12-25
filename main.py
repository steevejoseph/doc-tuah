from fastapi import FastAPI
from api import v1
import chromadb

app = FastAPI()

app.include_router(v1.router, prefix="/api/v1")


@app.get("/")
def read_root():
    return {"Hello": "World"}


chroma_client = chromadb.HttpClient(host="20.169.211.240", port=8000)

print(f"chroma hearbeat: {chroma_client.heartbeat()}")
