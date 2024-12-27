# Standard library imports
import argparse
import time

# Third-party imports
from langchain.prompts import ChatPromptTemplate
from langchain_ollama import OllamaLLM
from langchain_openai import AzureOpenAI

# Local application imports
from app.services.utils.get_model import get_model
from app.services.utils.chroma_client import get_chroma_client


PROMPT_TEMPLATE = """
Answer the question based only on the following context:

{context}

---

Answer the question based on the above context: {question}
"""


def main():
    # Create CLI.
    parser = argparse.ArgumentParser()
    parser.add_argument("query_text", type=str, help="The query text.")
    args = parser.parse_args()
    query_text = args.query_text
    query_rag(query_text)


def stream_response(model: AzureOpenAI | OllamaLLM, prompt) -> str:
    print("Response:", end=" ", flush=True)
    response_text = ""

    start_time = time.time()
    first_chunk = True

    for chunk in model.stream(prompt):
        if first_chunk:
            first_chunk_time = time.time() - start_time
            print(f"\n⏱️ Time to first token: {first_chunk_time:.2f}s")
            first_chunk = False

        chunk_text = str(chunk)
        print(chunk_text, end="", flush=True)
        response_text += chunk_text

    print("\n")
    return response_text


def query_rag(query_text: str, doc_id: str = None) -> str:
    # Prepare the DB.
    db = get_chroma_client()

    # TODO(steevejoseph): Implement filtering by doc_id
    # docs = db.get()
    # ids = docs["ids"]
    # where_document = {"$contains": f"(?){doc_id}"} if doc_id else {}

    # Search the DB.
    results = db.similarity_search_with_score(query_text, k=5)

    context_text = "\n\n---\n\n".join([doc.page_content for doc, _score in results])
    prompt_template = ChatPromptTemplate.from_template(PROMPT_TEMPLATE)
    prompt = prompt_template.format(context=context_text, question=query_text)
    # print(prompt)

    model = get_model()

    # Prefer streaming until API is ready to return
    # TODO(steevejoseph): Re-enable and have API return
    # just the big chunk
    # response_text = model.invoke(model, prompt)
    response_text = stream_response(model, prompt)

    sources = [doc.metadata.get("id", None) for doc, _score in results]
    formatted_response = f"Response: {response_text}\nSources: {sources}"
    print(formatted_response)
    return response_text

if __name__ == "__main__":
    main()
