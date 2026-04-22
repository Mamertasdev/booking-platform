from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.appointment import router as appointment_router
from app.api.auth import router as auth_router
from app.api.availability import router as availability_router
from app.api.availability_exception import router as availability_exception_router
from app.api.business import router as business_router
from app.api.public.availability import router as public_availability_router
from app.api.public.book import router as public_book_router
from app.api.public.service import router as public_service_router
from app.api.public.specialist import router as public_specialist_router
from app.api.service import router as service_router
from app.api.specialist import router as specialist_router
from app.api.working_hour import router as working_hour_router
from app.core.settings import settings
from app.database.init_db import init_db


def _get_cors_origins() -> list[str]:
    cors_origins = getattr(settings, "CORS_ORIGINS", None)

    if cors_origins:
        return cors_origins

    return [
        "http://localhost:3000",
        "http://100.80.21.21:3000",
    ]


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version="0.1",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api")
app.include_router(business_router, prefix="/api")
app.include_router(specialist_router, prefix="/api")
app.include_router(service_router, prefix="/api")
app.include_router(appointment_router, prefix="/api")
app.include_router(working_hour_router, prefix="/api")
app.include_router(availability_exception_router, prefix="/api")
app.include_router(availability_router, prefix="/api")

app.include_router(public_specialist_router, prefix="/public")
app.include_router(public_service_router, prefix="/public")
app.include_router(public_availability_router, prefix="/public")
app.include_router(public_book_router, prefix="/public")


@app.get("/")
def root():
    return {"status": "running", "app": settings.APP_NAME}


@app.get("/health")
def health():
    return {"status": "ok"}