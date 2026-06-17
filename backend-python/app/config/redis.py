"""Async Redis client."""

import redis.asyncio as aioredis

from app.config.settings import settings

_redis: aioredis.Redis | None = None


class RedisKeys:
    PREFIX = "baraqah"

    @staticmethod
    def match_results(user_id: str, geohash: str) -> str:
        return f"baraqah:match:results:{user_id}:{geohash}"

    @staticmethod
    def score_cache(user_id: str) -> str:
        return f"baraqah:score:cache:{user_id}"

    @staticmethod
    def score_leaderboard() -> str:
        return "baraqah:score:leaderboard"

    @staticmethod
    def score_leaderboard_city(city: str) -> str:
        return f"baraqah:score:leaderboard:city:{city}"


async def connect_redis():
    global _redis
    _redis = aioredis.from_url(settings.redis_url, decode_responses=True)
    await _redis.ping()
    return _redis


async def disconnect_redis():
    global _redis
    if _redis:
        await _redis.close()
        _redis = None


def get_redis() -> aioredis.Redis:
    if _redis is None:
        raise RuntimeError("Redis not connected")
    return _redis
