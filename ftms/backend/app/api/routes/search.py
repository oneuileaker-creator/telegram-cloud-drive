# app/api/routes/search.py

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import datetime

from app.database.connection import get_db
from app.database.models import User
from app.database.schemas import FileResponse
from app.services.search_service import SearchService
from app.api.middleware import get_current_user

router = APIRouter(prefix="/api/search", tags=["Search"])


@router.get("/")
async def search(
    q: str = Query(default="", description="Search query"),
    category: Optional[str] = Query(default=None),
    folder_id: Optional[str] = Query(default=None),
    is_favorite: Optional[bool] = Query(default=None),
    date_from: Optional[datetime] = Query(default=None),
    date_to: Optional[datetime] = Query(default=None),
    min_size_mb: Optional[float] = Query(default=None),
    max_size_mb: Optional[float] = Query(default=None),
    sort_by: str = Query(default="created_at"),
    sort_order: str = Query(default="desc"),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Full text search with all filters"""
    result = await SearchService.search_files(
        db=db,
        user_id=current_user.id,
        query=q,
        category=category,
        folder_id=folder_id,
        is_favorite=is_favorite,
        date_from=date_from,
        date_to=date_to,
        min_size=int(min_size_mb * 1024 * 1024) if min_size_mb else None,
        max_size=int(max_size_mb * 1024 * 1024) if max_size_mb else None,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        limit=limit
    )

    return {
        "files": [FileResponse.model_validate(f) for f in result["files"]],
        "total": result["total"],
        "page": page,
        "limit": limit,
        "has_more": result["has_more"],
        "query": q
    }


@router.get("/stats")
async def storage_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get storage breakdown by category"""
    return await SearchService.get_storage_stats(db, current_user.id)


@router.get("/recent")
async def recent_files(
    days: int = Query(default=7, ge=1, le=30),
    limit: int = Query(default=20, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get recently uploaded files"""
    files = await SearchService.get_recent_files(
        db, current_user.id, days, limit
    )
    return {
        "files": [FileResponse.model_validate(f) for f in files],
        "days": days
    }
