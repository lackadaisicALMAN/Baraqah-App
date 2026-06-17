"""Async MongoDB connection via Motor."""

from motor.motor_asyncio import AsyncIOMotorClient

from app.config.settings import settings

_client: AsyncIOMotorClient | None = None
_db = None


async def connect_mongo():
    global _client, _db
    _client = AsyncIOMotorClient(settings.mongo_uri)
    _db = _client.get_default_database()
    await _client.admin.command("ping")
    return _db


async def disconnect_mongo():
    global _client, _db
    if _client:
        _client.close()
        _client = None
        _db = None


def get_mongo_db():
    if _db is None:
        raise RuntimeError("MongoDB not connected")
    return _db
