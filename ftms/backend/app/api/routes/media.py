# app/api/routes/media.py

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional

from app.database.connection import get_db
from app.database.models import User, File as FileModel
from app.database.schemas import FileListResponse, FileResponse
from app.services.telegram_service import TelegramService
from app.api.middleware import get_current_user, get_telegram_user

router = APIRouter(prefix="/api/media", tags=["Media"])


@router.get("/photos", response_model=FileListResponse)
async def get_photos(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all photos - Gallery view"""
    from app.services.search_service import SearchService
    result = await SearchService.search_files(
        db, current_user.id,
        category="image",
        page=page, limit=limit,
        sort_by="created_at", sort_order="desc"
    )
    return FileListResponse(
        files=[FileResponse.model_validate(f) for f in result["files"]],
        total=result["total"],
        page=page,
        limit=limit,
        has_more=result["has_more"]
    )


@router.get("/videos", response_model=FileListResponse)
async def get_videos(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from app.services.search_service import SearchService
    result = await SearchService.search_files(
        db, current_user.id,
        category="video",
        page=page, limit=limit
    )
    return FileListResponse(
        files=[FileResponse.model_validate(f) for f in result["files"]],
        total=result["total"],
        page=page, limit=limit,
        has_more=result["has_more"]
    )


@router.get("/audio", response_model=FileListResponse)
async def get_audio(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from app.services.search_service import SearchService
    result = await SearchService.search_files(
        db, current_user.id,
        category="audio",
        page=page, limit=limit
    )
    return FileListResponse(
        files=[FileResponse.model_validate(f) for f in result["files"]],
        total=result["total"],
        page=page, limit=limit,
        has_more=result["has_more"]
    )


@router.get("/thumbnail/{file_id}")
async def get_thumbnail(
    file_id: str,
    current_user: User = Depends(get_telegram_user),
    db: AsyncSession = Depends(get_db)
):
    """Fetch thumbnail image for a file"""
    result = await db.execute(
        select(FileModel).where(
            FileModel.id == file_id,
            FileModel.user_id == current_user.id
        )
    )
    file_record = result.scalar_one_or_none()

    if not file_record or not file_record.thumbnail_message_id:
        return Response(status_code=404)

    tg = TelegramService(
        api_id=int(current_user.telegram_api_id),
        api_hash=current_user.telegram_api_hash,
        session_string=current_user.telegram_session
    )

    try:
        thumb_data = await tg.download_file(
            file_record.thumbnail_message_id,
            current_user.telegram_channel_id
        )
        return Response(
            content=thumb_data,
            media_type="image/jpeg",
            headers={"Cache-Control": "max-age=86400"}
        )
    finally:
        await tg.disconnect()


@router.get("/favorites", response_model=FileListResponse)
async def get_favorites(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from app.services.search_service import SearchService
    result = await SearchService.get_favorites(
        db, current_user.id, page, limit
    )
    return FileListResponse(
        files=[FileResponse.model_validate(f) for f in result["files"]],
        total=result["total"],
        page=page, limit=limit,
        has_more=False
    )
