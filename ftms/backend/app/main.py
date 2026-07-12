# app/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database.connection import init_db, close_db
from app.api.routes import auth, files, folders, media, search
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="FTMS - Unlimited Cloud Storage via Telegram API"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.FRONTEND_URL, "*"],  # Allow configured frontend and wildcard fallback
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Startup and Shutdown events
@app.on_event("startup")
async def on_startup():
    logger.info("Starting up application...")
    await init_db()


@app.on_event("shutdown")
async def on_shutdown():
    logger.info("Shutting down application...")
    await close_db()


# Include routers
app.include_router(auth.router)
app.include_router(files.router)
app.include_router(folders.router)
app.include_router(media.router)
app.include_router(search.router)


@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "healthy"
    }
