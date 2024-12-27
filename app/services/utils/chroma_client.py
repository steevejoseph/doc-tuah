# Standard library imports
import os

# Third-party imports
from chromadb.config import Settings
from langchain_chroma import Chroma

# Local application imports
from app.services.get_embedding_function import get_embedding_function
from app.core.config import get_settings

# Constants
DATA_PATH = os.path.join(os.path.dirname(__file__), "..", "data")

def get_chroma_client():
    settings = get_settings()

    if settings.DEBUG_USE_LOCAL_CHROMA:
        # Use local Chroma instance for debugging
        return Chroma(
            persist_directory=settings.CHROMA_LOCAL_PATH,
            embedding_function=get_embedding_function(),
        )

    # Use remote Chroma client (default for both development and production)
    chroma_settings = Settings(
        chroma_api_impl=settings.CHROMA_API_IMPL,
        chroma_server_host=settings.CHROMA_HOST,
        chroma_server_http_port=settings.CHROMA_PORT,
        chroma_server_ssl_enabled=settings.CHROMA_SSL,
    )

    return Chroma(
        client_settings=chroma_settings, embedding_function=get_embedding_function()
    )
