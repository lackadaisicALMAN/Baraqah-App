"""Pydantic schemas for scoring endpoints."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ScoreBaraqahRequest(BaseModel):
    user_id: str
    recalculate: bool = False


class ScoreComponent(BaseModel):
    name: str
    value: float
    weight: float
    contribution: float


class ScoreBaraqahResponse(BaseModel):
    user_id: str
    baraqah_score: float
    rank: Optional[int] = None
    city_rank: Optional[int] = None
    components: list[ScoreComponent]
    last_calculated_at: datetime
    cached: bool = False


class LeaderboardEntry(BaseModel):
    user_id: str
    full_name: str
    display_name: Optional[str]
    baraqah_score: float
    rank: int
