import os

from dotenv import load_dotenv

load_dotenv()


def _get_env(name: str, default: str | None = None, required: bool = False):
    value = os.getenv(name, default)

    if required and (value is None or value.strip() == ""):
        raise RuntimeError(f"Missing required environment variable: {name}")

    return value


class Settings:
    ENV: str = _get_env("ENV", "development")

    APP_NAME: str = _get_env("APP_NAME", "Booking Platform")

    SECRET_KEY: str = _get_env("SECRET_KEY", required=True)

    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        _get_env("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    )

    DEBUG: bool = ENV != "production"


settings = Settings()