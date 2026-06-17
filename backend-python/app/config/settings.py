"""Application settings loaded from environment variables."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Baraqah ML Service"
    debug: bool = False
    log_level: str = "info"

    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "baraqah"
    postgres_user: str = "baraqah"
    postgres_password: str = "baraqah_secret_change_me"

    mongo_uri: str = "mongodb://localhost:27017/baraqah"
    redis_url: str = "redis://localhost:6379/0"

    match_cache_ttl: int = 300
    score_cache_ttl: int = 900

    @property
    def postgres_dsn(self) -> str:
        return (
            f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


settings = Settings()
