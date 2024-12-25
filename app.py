from fastapi import FastAPI
from pydantic import BaseModel

from query_data import query_rag


app = FastAPI()


class Query(BaseModel):
    query: str
    source: str | None = None


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/query")
async def post_query(query: Query):
    print(f"Query is: {query}")
    ans = query_rag(query.query, query.source)
    return ans
