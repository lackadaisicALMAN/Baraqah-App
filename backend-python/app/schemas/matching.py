"""Pydantic schemas for matching endpoints."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class MatchSessionsRequest(BaseModel):
    user_id: str
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    radius_km: float = Field(default=10.0, ge=0.5, le=50)
    limit: int = Field(default=20, ge=1, le=100)


class SessionMatchResult(BaseModel):
    session_id: str
    host_user_id: str
    restaurant_id: str
    restaurant_name: str
    food_category: str
    scheduled_at: datetime
    distance_km: float
    similarity_score: float
    match_reasons: list[str]
    current_attendees: int
    max_attendees: int
    host_baraqah_score: float


class MatchSessionsResponse(BaseModel):
    user_id: str
    matches: list[SessionMatchResult]
    total: int
    cached: bool = False
