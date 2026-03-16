from fastapi import FastAPI
from app.core.settings import settings
from app.database.init_db import init_db
from app.api.business import router as business_router
from app.api.specialist import router as specialist_router
from app.api.service import router as service_router
from app.api.appointment import router as appointment_router
from app.api.working_hour import router as working_hour_router

app = FastAPI(
    title=settings.APP_NAME,
    version="0.1"
)

@app.on_event("startup")
def startup():
    init_db()

app.include_router(business_router, prefix="/api")
app.include_router(specialist_router, prefix="/api")
app.include_router(service_router, prefix="/api")
app.include_router(appointment_router, prefix="/api")
app.include_router(working_hour_router, prefix="/api")

@app.get("/")
def root():
    return {"status": "running", "app": settings.APP_NAME}