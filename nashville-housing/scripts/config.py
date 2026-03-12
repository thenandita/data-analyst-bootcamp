"""DB connection: Pydantic settings from db/.env and SQLAlchemy engine."""

import functools
from pathlib import Path
from urllib.parse import quote_plus

from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import create_engine

_ENV_FILE = Path(__file__).resolve().parent.parent / "db" / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    postgres_user: str
    postgres_password: str
    postgres_db: str = "nashville-housing"
    postgres_port: int = 5432
    postgres_host: str = "localhost"
    table_name: str = "nashville_housing"

    @property
    def database_url(self) -> str:
        u = quote_plus(self.postgres_user)
        p = quote_plus(self.postgres_password)
        return f"postgresql://{u}:{p}@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"


@functools.cache
def get_settings() -> Settings:
    return Settings()


@functools.cache
def get_engine():
    return create_engine(get_settings().database_url, pool_pre_ping=True)


def get_table_name() -> str:
    return get_settings().table_name
