from fastapi import FastAPI

app = FastAPI(
    title="Booking Platform API",
    version="0.1"
)

@app.get("/")
def root():
    return {"status": "running"}