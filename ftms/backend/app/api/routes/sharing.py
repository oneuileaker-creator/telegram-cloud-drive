from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from fastapi.responses import RedirectResponse
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import uuid
import secrets

from app.database.connection import get_db
from app.database.models import User, File as FileModel
from app.api.middleware import get_current_user
from app.services.telegram_service import TelegramService
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/share", tags=["Sharing"])

# ─── In-memory store (use Redis in production) ─────────────

_share_store: dict[str, dict] = {}


class CreateShareRequest(BaseModel):
    file_id: str
    expires_in_hours: Optional[int] = None
    password: Optional[str] = None
    max_downloads: Optional[int] = None


@router.post("/create")
async def create_share_link(
    data: CreateShareRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Verify file belongs to user
    result = await db.execute(
        select(FileModel).where(
            FileModel.id == data.file_id,
            FileModel.user_id == current_user.id,
            FileModel.upload_status == "complete"
        )
    )
    file = result.scalar_one_or_none()
    if not file:
        raise HTTPException(status_code=404, detail="File not found")

    link_id  = str(uuid.uuid4())
    token    = secrets.token_urlsafe(32)
    base_url = "https://ftms-backend.onrender.com"
    url      = f"{base_url}/api/share/download/{token}"

    expires_at = None
    if data.expires_in_hours:
        expires_at = (
            datetime.utcnow() +
            timedelta(hours=data.expires_in_hours)
        ).isoformat()

    _share_store[token] = {
        "id":             link_id,
        "file_id":        data.file_id,
        "user_id":        str(current_user.id),
        "url":            url,
        "token":          token,
        "expires_at":     expires_at,
        "password":       data.password,
        "max_downloads":  data.max_downloads,
        "download_count": 0,
        "is_active":      True,
        "created_at":     datetime.utcnow().isoformat()
    }

    return {
        "id":             link_id,
        "file_id":        data.file_id,
        "url":            url,
        "token":          token,
        "expires_at":     expires_at,
        "has_password":   data.password is not None,
        "max_downloads":  data.max_downloads,
        "download_count": 0,
        "is_active":      True,
        "created_at":     datetime.utcnow().isoformat()
    }


@router.get("/list")
async def list_share_links(
    current_user: User = Depends(get_current_user)
):
    user_links = [
        v for v in _share_store.values()
        if v["user_id"] == str(current_user.id)
    ]
    return {"links": user_links}


@router.delete("/{link_id}")
async def revoke_share_link(
    link_id: str,
    current_user: User = Depends(get_current_user)
):
    for token, link in list(_share_store.items()):
        if (link["id"] == link_id and
                link["user_id"] == str(current_user.id)):
            del _share_store[token]
            return {"message": "Link revoked"}
    raise HTTPException(status_code=404, detail="Link not found")


@router.get("/download/{token}")
async def download_shared_file(
    token: str,
    password: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """Public endpoint - no auth required"""
    link = _share_store.get(token)
    if not link or not link["is_active"]:
        raise HTTPException(status_code=404, detail="Link not found or expired")

    # Check expiry
    if link["expires_at"]:
        if datetime.utcnow() > datetime.fromisoformat(link["expires_at"]):
            raise HTTPException(status_code=410, detail="Link has expired")

    # Check password
    if link["password"] and link["password"] != password:
        raise HTTPException(status_code=401, detail="Invalid password")

    # Check download limit
    if (link["max_downloads"] and
            link["download_count"] >= link["max_downloads"]):
        raise HTTPException(
            status_code=410,
            detail="Download limit reached"
        )

    # Increment download count
    link["download_count"] += 1

    # Get file and stream from Telegram
    result = await db.execute(
        select(FileModel, User)
        .join(User, User.id == FileModel.user_id)
        .where(FileModel.id == link["file_id"])
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="File not found")

    file_record, owner = row

    from fastapi.responses import StreamingResponse

    tg = TelegramService(
        api_id=int(owner.telegram_api_id),
        api_hash=owner.telegram_api_hash,
        session_string=owner.telegram_session
    )

    async def stream():
        try:
            for msg_id in file_record.telegram_message_ids:
                chunk = await tg.download_file(
                    msg_id,
                    owner.telegram_channel_id
                )
                yield chunk
        finally:
            await tg.disconnect()

    return StreamingResponse(
        stream(),
        media_type=file_record.mime_type or "application/octet-stream",
        headers={
            "Content-Disposition":
                f'attachment; filename="{file_record.original_name}"'
        }
    )
