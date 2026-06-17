"""Baraqah Score computation service."""

import json
from datetime import datetime, timezone

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.redis import RedisKeys, get_redis
from app.config.settings import settings
from app.ml.score_model import compute_baraqah_score
from app.schemas.scoring import ScoreBaraqahRequest, ScoreBaraqahResponse, ScoreComponent
from app.utils.logger import get_logger

logger = get_logger()


async def _fetch_user_stats(db: AsyncSession, user_id: str) -> dict | None:
    result = await db.execute(
        text(
            """SELECT id, full_name, display_name, baraqah_score,
                      total_sessions, total_hosted, total_no_shows
               FROM users WHERE id = :uid AND deleted_at IS NULL"""
        ),
        {"uid": user_id},
    )
    row = result.mappings().first()
    return dict(row) if row else None


async def _fetch_score_events(db: AsyncSession, user_id: str) -> list[dict]:
    result = await db.execute(
        text(
            """SELECT event_type, delta, score_before, score_after, created_at
               FROM baraqah_score_events
               WHERE user_id = :uid
               ORDER BY created_at DESC
               LIMIT 100"""
        ),
        {"uid": user_id},
    )
    return [dict(row) for row in result.mappings().all()]


async def _fetch_social_stats(db: AsyncSession, user_id: str) -> dict:
    result = await db.execute(
        text(
            """SELECT COUNT(*) AS friend_count
               FROM friendships
               WHERE (requester_id = :uid OR addressee_id = :uid)
                 AND status = 'ACCEPTED'"""
        ),
        {"uid": user_id},
    )
    row = result.mappings().first()
    return {"friend_count": int(row["friend_count"]) if row else 0}


async def _compute_rank(db: AsyncSession, user_id: str, score: float) -> int:
    result = await db.execute(
        text(
            """SELECT COUNT(*) + 1 AS rank FROM users
               WHERE baraqah_score > :score AND deleted_at IS NULL"""
        ),
        {"score": score},
    )
    row = result.mappings().first()
    return int(row["rank"]) if row else 1


async def calculate_baraqah_score(
    db: AsyncSession, request: ScoreBaraqahRequest
) -> ScoreBaraqahResponse:
    """Calculate or retrieve cached Baraqah Score for a user."""
    redis = get_redis()
    cache_key = RedisKeys.score_cache(request.user_id)

    if not request.recalculate:
        cached = await redis.hgetall(cache_key)
        if cached and cached.get("score"):
            return ScoreBaraqahResponse(
                user_id=request.user_id,
                baraqah_score=float(cached["score"]),
                rank=int(cached["rank"]) if cached.get("rank") else None,
                components=[],
                last_calculated_at=datetime.fromisoformat(
                    cached.get("last_calculated_at", datetime.now(timezone.utc).isoformat())
                ),
                cached=True,
            )

    user_stats = await _fetch_user_stats(db, request.user_id)
    if not user_stats:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="User not found")

    score_events = await _fetch_score_events(db, request.user_id)
    social_stats = await _fetch_social_stats(db, request.user_id)

    final_score, breakdown = compute_baraqah_score(
        user_stats, score_events, social_stats
    )

    await db.execute(
        text("UPDATE users SET baraqah_score = :score WHERE id = :uid"),
        {"score": final_score, "uid": request.user_id},
    )
    await db.commit()

    rank = await _compute_rank(db, request.user_id, final_score)
    now = datetime.now(timezone.utc)

    await redis.hset(
        cache_key,
        mapping={
            "score": str(final_score),
            "rank": str(rank),
            "last_calculated_at": now.isoformat(),
        },
    )
    await redis.expire(cache_key, settings.score_cache_ttl)

    await redis.zadd(RedisKeys.score_leaderboard(), {request.user_id: final_score})

    components = [ScoreComponent(**c) for c in breakdown]

    logger.info(
        "score_calculated",
        user_id=request.user_id,
        score=final_score,
        rank=rank,
    )

    return ScoreBaraqahResponse(
        user_id=request.user_id,
        baraqah_score=final_score,
        rank=rank,
        components=components,
        last_calculated_at=now,
        cached=False,
    )
