from langchain_ollama import OllamaEmbeddings
from langchain_openai import AzureOpenAIEmbeddings


def get_embedding_function():
    # Use Ollama embeddings for local debugging
    embeddings = OllamaEmbeddings(model="mistral")

    # Use an Azure OpenAI embedding on PROD

    # embeddings = AzureOpenAIEmbeddings(
    #     azure_endpoint="https://YOUR_RESOURCE_NAME.openai.azure.com",
    #     api_key="YOUR_API_KEY",
    #     api_version="2024-02-15-preview",
    #     deployment_name="YOUR_EMBEDDING_DEPLOYMENT_NAME",  # e.g., text-embedding-ada-002
    # )

    return embeddings
