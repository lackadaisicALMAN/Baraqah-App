"""Matching API endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_db
from app.schemas.matching import MatchSessionsRequest, MatchSessionsResponse
from app.services.matching_service import match_sessions

router = APIRouter(prefix="/match", tags=["matching"])


@router.post("/sessions", response_model=MatchSessionsResponse)
async def match_sessions_endpoint(
    request: MatchSessionsRequest,
    db: AsyncSession = Depends(get_db),
):
    """Rank open dining sessions by preference similarity for a user."""
    return await match_sessions(db, request)
