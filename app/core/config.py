from pydantic_settings import BaseSettings
from functools import lru_cache
import os


class Settings(BaseSettings):
    # Environment
    ENV: str = "development"  # "development" or "production"

    # Debug flags
    DEBUG_USE_LOCAL_MODEL: bool = False
    DEBUG_USE_LOCAL_CHROMA: bool = False

    # Azure OpenAI Settings
    AZURE_OPENAI_API_KEY: str | None = None
    AZURE_OPENAI_ENDPOINT: str | None = None
    AZURE_OPENAI_API_VERSION: str | None = None
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT: str | None = None
    AZURE_OPENAI_CHAT_DEPLOYMENT: str | None = None

    # ChromaDB Settings
    CHROMA_HOST: str | None = None
    CHROMA_PORT: str | None = None
    CHROMA_SSL: bool = False
    CHROMA_API_IMPL: str = ""

    # Local Debug Settings
    LOCAL_MODEL_NAME: str = ""
    CHROMA_LOCAL_PATH: str = ""

    class Config:
        env_file = f".env.{os.getenv('ENV', 'development')}"


@lru_cache()
def get_settings():
    return Settings()
