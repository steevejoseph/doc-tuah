from langchain_ollama import OllamaEmbeddings
from langchain_openai import AzureOpenAIEmbeddings
from app.core.config import get_settings


def get_embedding_function():
    settings = get_settings()

    if settings.DEBUG_USE_LOCAL_MODEL:
        return OllamaEmbeddings(model=settings.LOCAL_MODEL_NAME)

    return AzureOpenAIEmbeddings(
        azure_endpoint=settings.AZURE_OPENAI_ENDPOINT,
        api_key=settings.AZURE_OPENAI_API_EMBEDDING_DEPLOYMENT_KEY,
        api_version=settings.AZURE_OPENAI_API_VERSION,
        azure_deployment=settings.AZURE_OPENAI_EMBEDDING_DEPLOYMENT,
    )
