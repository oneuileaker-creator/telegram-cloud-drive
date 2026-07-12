# app/api/routes/folders.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from uuid import UUID

from app.database.connection import get_db
from app.database.models import User
from app.database.schemas import FolderCreate, FolderResponse
from app.services.folder_service import FolderService
from app.api.middleware import get_current_user

router = APIRouter(prefix="/api/folders", tags=["Folders"])


@router.post("/", response_model=FolderResponse, status_code=201)
async def create_folder(
    data: FolderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    try:
        folder = await FolderService.create_folder(
            db, current_user.id, data
        )
        return FolderResponse.model_validate(folder)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/tree")
async def get_folder_tree(
    parent_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get folder tree starting from parent_id (None = root)"""
    tree = await FolderService.get_folder_tree(
        db,
        current_user.id,
        UUID(parent_id) if parent_id else None
    )
    return {"folders": tree}


@router.patch("/{folder_id}/rename")
async def rename_folder(
    folder_id: str,
    new_name: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    try:
        folder = await FolderService.rename_folder(
            db, current_user.id, UUID(folder_id), new_name
        )
        return FolderResponse.model_validate(folder)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{folder_id}/move")
async def move_folder(
    folder_id: str,
    new_parent_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    try:
        folder = await FolderService.move_folder(
            db,
            current_user.id,
            UUID(folder_id),
            UUID(new_parent_id) if new_parent_id else None
        )
        return FolderResponse.model_validate(folder)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{folder_id}")
async def delete_folder(
    folder_id: str,
    delete_files: bool = False,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    try:
        result = await FolderService.delete_folder(
            db, current_user.id, UUID(folder_id), delete_files
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
