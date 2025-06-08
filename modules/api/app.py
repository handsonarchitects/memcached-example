from fastapi import FastAPI
from pydantic import BaseModel
from pymemcache.client import base

import os
import logging
import sys

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

class CacheItem(BaseModel):
    key: str
    value: str | None = None

app = FastAPI()
logger = logging.getLogger("api")

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up the FastAPI application...")
    logger.debug("Using Memcached host: %s", os.getenv("MEMCACHED_HOST", "localhost"))

@app.get("/items/{key}")
async def read_cache_item(key: str):
    client = base.Client((os.getenv("MEMCACHED_HOST", "localhost"), 11211))
    value = client.get(key)
    if value is None:
        return {"error": "Key not found"}
    return {"key": key, "value": value.decode('utf-8')}

@app.post("/items/")
async def create_cache_item(item: CacheItem):
    client = base.Client((os.getenv("MEMCACHED_HOST", "localhost"), 11211))
    client.set(item.key, item.value)
    return {"status": "success"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
