# app/database/connection.py

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    create_async_engine,
    async_sessionmaker
)
from sqlalchemy.orm import DeclarativeBase
from app.config import settings
import asyncio
import logging

logger = logging.getLogger(__name__)


# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,          # Log SQL queries in debug mode
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,           # Check connection health
    pool_recycle=3600,            # Recycle connections every hour
)

# Session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,       # Don't expire after commit
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    """Dependency - get database session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            logger.error(f"Database error: {e}")
            raise
        finally:
            await session.close()


from urllib.parse import urlparse

async def init_db():
    """Create all tables on startup with retry logic"""
    max_retries = 5
    backoff = 2
    for attempt in range(1, max_retries + 1):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("✅ Database tables created successfully")
            return
        except Exception as e:
            try:
                parsed = urlparse(settings.DATABASE_URL)
                host_info = f"{parsed.hostname}:{parsed.port}" if parsed.port else parsed.hostname
            except Exception:
                host_info = "unknown"

            if attempt == max_retries:
                logger.error(f"❌ Failed to connect to database host '{host_info}' after {max_retries} attempts: {e}")
                raise e
            logger.warning(
                f"⚠️ Database connection attempt {attempt}/{max_retries} failed for host '{host_info}': {e}. "
                f"Retrying in {backoff} seconds..."
            )
            await asyncio.sleep(backoff)
            backoff *= 2


async def close_db():
    """Close database connections on shutdown"""
    await engine.dispose()
    logger.info("✅ Database connections closed")
