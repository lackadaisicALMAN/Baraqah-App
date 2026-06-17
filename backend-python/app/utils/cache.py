"""Redis cache decorator helpers."""

import functools
import json
from typing import Any, Callable

from app.config.redis import get_redis


def cache_result(key_fn: Callable[..., str], ttl: int = 300):
    """Decorator to cache async function results in Redis."""

    def decorator(func: Callable):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            redis = get_redis()
            key = key_fn(*args, **kwargs)
            cached = await redis.get(key)
            if cached:
                return json.loads(cached)

            result = await func(*args, **kwargs)
            await redis.set(key, json.dumps(result, default=str), ex=ttl)
            return result

        return wrapper

    return decorator


async def invalidate_cache(key: str) -> None:
    redis = get_redis()
    await redis.delete(key)
