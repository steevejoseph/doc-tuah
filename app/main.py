# Standard library imports
import time

# Third-party imports
import chromadb
import requests
from fastapi import FastAPI

# Local application imports
from app.api import v1

app = FastAPI()

app.include_router(v1.router, prefix="/api/v1")


@app.get("/")
def read_root():
    return {"Hello": "World"}

# @steeve: figure out env vars in Azure?
host = "52.191.113.76"
port = 8000


def test_connection():
    try:
        response = requests.get(f"http://{host}:{port}/api/v1/heartbeat", timeout=5)
        print(f"Server response: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"Connection test failed: {e}")
        return False


# Test basic connectivity first
if not test_connection():
    raise Exception("Could not connect to Chroma server")

# Initialize ChromaDB client
try:
    chroma_client = chromadb.HttpClient(host=host, port=port)
    print("ChromaDB client initialized successfully")

    # Test the connection with a heartbeat
    heartbeat = chroma_client.heartbeat()
    print(f"ChromaDB heartbeat: {heartbeat}")

    # List existing collections
    collections = chroma_client.list_collections()
    print(f"Existing collections: {collections}")

except Exception as e:
    print(f"Failed to initialize ChromaDB client: {e}")
    raise
