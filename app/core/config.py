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
    AZURE_OPENAI_API_CHAT_DEPLOYMENT_KEY: str = ""
    AZURE_OPENAI_API_EMBEDDING_DEPLOYMENT_KEY: str = ""
    AZURE_OPENAI_ENDPOINT: str = ""
    AZURE_OPENAI_API_VERSION: str = ""
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT: str = ""
    AZURE_OPENAI_CHAT_DEPLOYMENT: str = ""

    # ChromaDB Settings - read from env file by default
    CHROMA_HOST: str = ""
    CHROMA_PORT: str = ""
    CHROMA_SSL: bool = False
    CHROMA_API_IMPL: str = ""

    # Local Debug Settings
    LOCAL_MODEL_NAME: str = ""
    CHROMA_LOCAL_PATH: str = ""

    class Config:
        env_file = f".env.{os.getenv('ENV', 'development')}"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Only override CHROMA_HOST when using local ChromaDB
        if self.DEBUG_USE_LOCAL_CHROMA:
            self.CHROMA_HOST = "localhost"


@lru_cache()
def get_settings():
    return Settings()
