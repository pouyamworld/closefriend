from functools import lru_cache
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    BACKEND_CORS_ORIGINS: str = ""
    GOOGLE_CLIENT_ID: str | None = None
    TELEGRAM_BOT_TOKEN: str | None = None
    TELEGRAM_AUTH_MAX_AGE: int = 300
    DATABASE_URL: str = "postgresql+psycopg://postgres:postgres@localhost:5432/closefriend"
    ENVIRONMENT: str = "dev"  # dev | prod

    class Config:
        env_file = ".env"
        case_sensitive = False

    @property
    def cors_origin_list(self) -> List[str]:
        if not self.BACKEND_CORS_ORIGINS:
            return []
        return [o.strip() for o in self.BACKEND_CORS_ORIGINS.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "prod"

@lru_cache()
def get_settings() -> Settings:
    return Settings()
