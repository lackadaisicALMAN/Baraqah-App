"""Aggregate all v1 API routers."""

from fastapi import APIRouter

from app.api.v1.matching import router as matching_router
from app.api.v1.scoring import router as scoring_router

router = APIRouter(prefix="/api/v1")
router.include_router(matching_router)
router.include_router(scoring_router)
