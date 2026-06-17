"""Core matching algorithm — ranks open sessions for a user."""

import json
from datetime import datetime

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.config.redis import RedisKeys, get_redis
from app.config.settings import settings
from app.ml.feature_engineering import (
    build_preference_vector,
    build_session_vector,
    extract_session_features,
    extract_user_features,
)
from app.ml.similarity import compute_match_reasons, weighted_similarity
from app.schemas.matching import MatchSessionsRequest, MatchSessionsResponse, SessionMatchResult
from app.services.preference_service import get_user_preference_vector
from app.utils.logger import get_logger

logger = get_logger()

FEATURE_WEIGHTS = [
    1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5,  # cuisine (8)
    1.2,  # price
    1.0,  # social comfort / group fit
    1.3,  # host score
    0.8,  # group fill
    1.0,  # distance
    0.7,  # time
    0.9,  # ride
]


def _geohash(lat: float, lng: float) -> str:
    return f"{lat:.4f}:{lng:.4f}"


async def _fetch_user(db: AsyncSession, user_id: str) -> dict | None:
    result = await db.execute(
        text(
            """SELECT id, full_name, baraqah_score, total_sessions, total_hosted,
                      total_no_shows
               FROM users WHERE id = :uid AND deleted_at IS NULL"""
        ),
        {"uid": user_id},
    )
    row = result.mappings().first()
    return dict(row) if row else None


async def _fetch_open_sessions(
    db: AsyncSession, lat: float, lng: float, radius_km: float, limit: int
) -> list[dict]:
    result = await db.execute(
        text(
            """SELECT ds.id, ds.host_user_id, ds.restaurant_id, ds.status,
                      ds.scheduled_at, ds.max_attendees, ds.current_attendees,
                      ds.food_category, ds.split_type, ds.has_ride_available,
                      ds.available_ride_seats, ds.description,
                      r.name AS restaurant_name, r.cuisine_tags, r.price_range,
                      u.baraqah_score AS host_score,
                      ST_Distance(
                        ds.meeting_location::geography,
                        ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography
                      ) / 1000 AS distance_km
               FROM dining_sessions ds
               JOIN restaurants r ON r.id = ds.restaurant_id
               JOIN users u ON u.id = ds.host_user_id
               WHERE ds.status = 'OPEN'
                 AND ds.meeting_location IS NOT NULL
                 AND ST_DWithin(
                       ds.meeting_location::geography,
                       ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
                       :radius * 1000
                     )
               ORDER BY distance_km
               LIMIT :limit"""
        ),
        {"lat": lat, "lng": lng, "radius": radius_km, "limit": limit * 3},
    )
    return [dict(row) for row in result.mappings().all()]


async def match_sessions(
    db: AsyncSession, request: MatchSessionsRequest
) -> MatchSessionsResponse:
    """Find and rank matching sessions for a user."""
    redis = get_redis()
    geohash = _geohash(request.lat, request.lng)
    cache_key = RedisKeys.match_results(request.user_id, geohash)

    if not request.__dict__.get("_skip_cache"):
        cached = await redis.get(cache_key)
        if cached:
            data = json.loads(cached)
            return MatchSessionsResponse(
                user_id=request.user_id,
                matches=[SessionMatchResult(**m) for m in data["matches"]],
                total=data["total"],
                cached=True,
            )

    pg_user = await _fetch_user(db, request.user_id)
    if not pg_user:
        return MatchSessionsResponse(
            user_id=request.user_id, matches=[], total=0
        )

    user_vector, user_features = await get_user_preference_vector(
        request.user_id, pg_user
    )

    sessions = await _fetch_open_sessions(
        db, request.lat, request.lng, request.radius_km, request.limit
    )

    matches = []
    for session in sessions:
        if session["host_user_id"] == request.user_id:
            continue

        restaurant = {
            "name": session.get("restaurant_name"),
            "cuisine_tags": session.get("cuisine_tags", []),
            "price_range": session.get("price_range"),
        }
        session_features = extract_session_features(session, restaurant)
        session_vector = build_session_vector(session_features, user_features)

        similarity = weighted_similarity(user_vector, session_vector, FEATURE_WEIGHTS)
        reasons = compute_match_reasons(user_features, session_features, similarity)

        scheduled = session.get("scheduled_at")
        if isinstance(scheduled, datetime):
            scheduled_dt = scheduled
        else:
            scheduled_dt = datetime.fromisoformat(str(scheduled))

        matches.append(
            SessionMatchResult(
                session_id=session["id"],
                host_user_id=session["host_user_id"],
                restaurant_id=session["restaurant_id"],
                restaurant_name=session.get("restaurant_name", ""),
                food_category=session.get("food_category", ""),
                scheduled_at=scheduled_dt,
                distance_km=round(float(session.get("distance_km", 0)), 2),
                similarity_score=round(similarity, 4),
                match_reasons=reasons,
                current_attendees=int(session.get("current_attendees", 1)),
                max_attendees=int(session.get("max_attendees", 4)),
                host_baraqah_score=float(session.get("host_score", 50)),
            )
        )

    matches.sort(key=lambda m: m.similarity_score, reverse=True)
    matches = matches[: request.limit]

    response = MatchSessionsResponse(
        user_id=request.user_id,
        matches=matches,
        total=len(matches),
        cached=False,
    )

    await redis.set(
        cache_key,
        json.dumps(
            {
                "matches": [m.model_dump(mode="json") for m in matches],
                "total": len(matches),
            },
            default=str,
        ),
        ex=settings.match_cache_ttl,
    )

    logger.info(
        "match_sessions_complete",
        user_id=request.user_id,
        match_count=len(matches),
    )

    return response
