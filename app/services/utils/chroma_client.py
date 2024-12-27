# Standard library imports
import os

# Third-party imports
from chromadb.config import Settings
from langchain_chroma import Chroma

# Local application imports
from app.services.get_embedding_function import get_embedding_function

# Constants
CHROMA_PATH = "chroma"
DATA_PATH = os.path.join(os.path.dirname(__file__), "..", "data")
CHROMA_HOST = "52.191.113.76"
CHROMA_PORT = "8000"
CHROMA_SSL = False
CHROMA_API_IMPL = "chromadb.api.fastapi.FastAPI"


def get_chroma_client():
    # Configure Chroma client for remote connection
    chroma_settings = Settings(
        chroma_api_impl=CHROMA_API_IMPL,  # Use REST API for remote connection
        chroma_server_host=CHROMA_HOST,
        chroma_server_http_port=CHROMA_PORT,
        chroma_server_ssl_enabled=CHROMA_SSL,
    )

    # Initialize and return Chroma with remote settings
    db = Chroma(
        client_settings=chroma_settings, embedding_function=get_embedding_function()
    )

    # Load the existing database on local.
    # db = Chroma(
    #     persist_directory=CHROMA_PATH, embedding_function=get_embedding_function()
    # )

    return db
