from pydantic import BaseModel


class Query(BaseModel):
    query: str
    source: str | None = None
