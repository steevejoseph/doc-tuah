# Third-party imports
from fastapi import APIRouter, HTTPException

# Local application imports
from app.api.v1.models import Query
from app.services import query_rag

router = APIRouter()


@router.post("/query")
async def post_query(query: Query):
    print(f"Query is: {query}")
    ans = query_rag(query.query, query.source)
    return ans
