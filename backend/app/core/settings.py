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

    DATABASE_URL: str = _get_env("DATABASE_URL", "sqlite:///./app.db")

    DEBUG: bool = ENV != "production"

    def __init__(self):
        self._validate_security_settings()

    def _validate_security_settings(self):
        if self.ENV != "production":
            return

        secret_key = self.SECRET_KEY.strip()

        if secret_key == "change-me":
            raise RuntimeError(
                "SECRET_KEY must be changed before running in production"
            )

        if len(secret_key) < 32:
            raise RuntimeError(
                "SECRET_KEY must be at least 32 characters in production"
            )


settings = Settings()