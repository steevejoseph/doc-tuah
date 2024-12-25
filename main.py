from fastapi import FastAPI
from api import v1

app = FastAPI()

app.include_router(v1.router, prefix="/api/v1")


@app.get("/")
def read_root():
    return {"Hello": "World"}
