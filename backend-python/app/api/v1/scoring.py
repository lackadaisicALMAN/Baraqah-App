"""Scoring API endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_db
from app.schemas.scoring import ScoreBaraqahRequest, ScoreBaraqahResponse
from app.services.scoring_service import calculate_baraqah_score

router = APIRouter(prefix="/score", tags=["scoring"])


@router.post("/baraqah", response_model=ScoreBaraqahResponse)
async def score_baraqah_endpoint(
    request: ScoreBaraqahRequest,
    db: AsyncSession = Depends(get_db),
):
    """Calculate composite Baraqah Score for a user."""
    return await calculate_baraqah_score(db, request)


@router.get("/baraqah/{user_id}", response_model=ScoreBaraqahResponse)
async def get_baraqah_score(
    user_id: str,
    recalculate: bool = False,
    db: AsyncSession = Depends(get_db),
):
    """Get Baraqah Score by user ID."""
    request = ScoreBaraqahRequest(user_id=user_id, recalculate=recalculate)
    return await calculate_baraqah_score(db, request)
