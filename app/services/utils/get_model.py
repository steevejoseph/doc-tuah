from langchain_ollama import OllamaLLM
from langchain_openai import AzureOpenAI
from app.core.config import get_settings


def get_model():
    settings = get_settings()

    if settings.DEBUG_USE_LOCAL_MODEL:
        return OllamaLLM(model=settings.LOCAL_MODEL_NAME)

    return AzureOpenAI(
        azure_endpoint=settings.AZURE_OPENAI_ENDPOINT,
        api_key=settings.AZURE_OPENAI_API_KEY,
        api_version=settings.AZURE_OPENAI_API_VERSION,
        deployment_name=settings.AZURE_OPENAI_CHAT_DEPLOYMENT,
    )
