"""FastAPI application factory with lifespan events."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import router as v1_router
from app.config.mongo import connect_mongo, disconnect_mongo
from app.config.redis import connect_redis, disconnect_redis
from app.config.settings import settings
from app.utils.logger import get_logger, setup_logging

logger = get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging(settings.log_level)
    logger.info("Starting Baraqah ML service")

    await connect_mongo()
    await connect_redis()

    yield

    await disconnect_mongo()
    await disconnect_redis()
    logger.info("Baraqah ML service stopped")


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health")
    async def health():
        return {
            "status": "ok",
            "service": "baraqah-python",
            "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
        }

    app.include_router(v1_router)

    return app


app = create_app()
