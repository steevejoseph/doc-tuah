# Old:
from langchain_ollama import OllamaLLM

# New:
from langchain_openai import AzureOpenAI


def get_model():
    # For debugging using local model
    model = OllamaLLM(model="mistral")

    # model = AzureOpenAI(
    #     azure_endpoint="https://YOUR_RESOURCE_NAME.openai.azure.com",
    #     api_key="YOUR_API_KEY",
    #     api_version="2024-02-15-preview",
    #     deployment_name="YOUR_DEPLOYMENT_NAME",
    # )
    return model
