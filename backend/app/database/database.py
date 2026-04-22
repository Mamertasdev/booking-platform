from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.settings import settings


def _is_sqlite_database(url: str) -> bool:
    return url.startswith("sqlite")


DATABASE_URL = settings.DATABASE_URL

engine_kwargs = {}

if _is_sqlite_database(DATABASE_URL):
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(
    DATABASE_URL,
    **engine_kwargs,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()