import logging
import os
import sys
from contextlib import asynccontextmanager
from typing import Any, AsyncGenerator, Dict

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pymemcache.client import base

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)


class CacheItem(BaseModel):
    key: str
    value: str | None = None


logger = logging.getLogger("api")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info("Starting up the FastAPI application...")
    logger.debug("Using Memcached host: %s", os.getenv("MEMCACHED_HOST", "localhost"))
    yield
    logger.info("Shutting down the FastAPI application...")


app = FastAPI(lifespan=lifespan)


@app.get("/items/{key}")
async def read_cache_item(key: str) -> Dict[str, str]:
    client = base.Client((os.getenv("MEMCACHED_HOST", "localhost"), 11211))
    value = client.get(key)
    if value is None:
        raise HTTPException(status_code=400, detail="Key not found")
    return {"key": key, "value": value.decode("utf-8")}


@app.post("/items/")
async def create_cache_item(item: CacheItem) -> Dict[str, str]:
    client = base.Client((os.getenv("MEMCACHED_HOST", "localhost"), 11211))
    client.set(item.key, item.value)
    return {"status": "success"}


@app.get("/health")
async def health() -> Dict[str, str]:
    return {"status": "healthy"}
