from langchain_ollama import OllamaEmbeddings


def get_embedding_function():
    # TODO(steevejoseph): Change this to use an Azure OpenAI embedding
    embeddings = OllamaEmbeddings(model="mistral")
    return embeddings
