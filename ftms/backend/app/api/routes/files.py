# app/api/routes/files.py

from fastapi import (
    APIRouter, Depends, HTTPException,
    UploadFile, File, BackgroundTasks,
    Query
)
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func, delete
from typing import Optional
import io
import hashlib
import logging

from app.database.connection import get_db
from app.database.models import User, File as FileModel, FileChunk, Folder
from app.database.schemas import (
    FileResponse, FileListResponse,
    UploadResponse, FileUpdate,
    FolderCreate, FolderResponse
)
from app.services.telegram_service import TelegramService
from app.api.middleware import get_current_user, get_telegram_user
from app.config import settings
from app.utils.helpers import (
    split_into_chunks,
    detect_file_type,
    format_file_size
)
from uuid import UUID

router = APIRouter(prefix="/api/files", tags=["Files"])
logger = logging.getLogger(__name__)


# ─── Background Upload Task ───────────────────────────────────

async def process_upload(
    file_data: bytes,
    file_record_id: str,
    user: User,
    db_url: str
):
    from app.database.connection import AsyncSessionLocal
    from sqlalchemy import update as sa_update
    from app.services.ftms.router import FTMSRouter

    async with AsyncSessionLocal() as db:
        try:
            result = await db.execute(
                select(FileModel).where(FileModel.id == file_record_id)
            )
            file_record = result.scalar_one_or_none()
            if not file_record:
                return

            # ── Run FTMS Pipeline ──────────────────────────────
            ftms_result = await FTMSRouter.process(
                file_data,
                file_record.original_name
            )

            # Update file record with FTMS data
            file_record.file_type = ftms_result.detection.category
            file_record.mime_type = ftms_result.detection.mime_type
            file_record.extension = ftms_result.detection.extension
            file_record.file_metadata = ftms_result.metadata
            file_record.checksum = ftms_result.checksum
            await db.commit()

            # ── Upload to Telegram ─────────────────────────────
            tg = TelegramService(
                api_id=int(user.telegram_api_id),
                api_hash=user.telegram_api_hash,
                session_string=user.telegram_session
            )
            channel_id = user.telegram_channel_id
            message_ids = []

            if len(file_data) > settings.CHUNK_SIZE_BYTES:
                from app.utils.helpers import split_into_chunks
                chunks = split_into_chunks(file_data, settings.CHUNK_SIZE_BYTES)
                file_record.is_chunked = True
                file_record.total_chunks = len(chunks)

                for index, chunk in enumerate(chunks):
                    chunk_record = FileChunk(
                        file_id=file_record.id,
                        chunk_index=index,
                        chunk_size=len(chunk),
                        upload_status="uploading",
                        checksum=hashlib.sha256(chunk).hexdigest()
                    )
                    db.add(chunk_record)
                    await db.commit()

                    msg_id = await tg.upload_file(
                        chunk,
                        f"{file_record.id}_chunk_{index}.bin",
                        channel_id
                    )
                    message_ids.append(msg_id)
                    chunk_record.telegram_message_id = msg_id
                    chunk_record.upload_status = "complete"
                    await db.commit()
            else:
                msg_id = await tg.upload_file(
                    file_data,
                    file_record.original_name,
                    channel_id
                )
                message_ids.append(msg_id)

            # ── Upload Thumbnail ───────────────────────────────
            thumb_msg_id = None
            if ftms_result.thumbnail:
                thumb_msg_id = await tg.upload_thumbnail(
                    ftms_result.thumbnail.data,
                    channel_id,
                    file_record.original_name
                )

            # ── Final Update ───────────────────────────────────
            await db.execute(
                sa_update(FileModel)
                .where(FileModel.id == file_record.id)
                .values(
                    telegram_message_ids=message_ids,
                    thumbnail_message_id=thumb_msg_id,
                    upload_status="complete"
                )
            )
            await db.execute(
                sa_update(User)
                .where(User.id == user.id)
                .values(
                    storage_used_bytes=User.storage_used_bytes + len(file_data),
                    total_files=User.total_files + 1
                )
            )
            await db.commit()
            logger.info(f"✅ FTMS Upload complete: {file_record.original_name}")

        except Exception as e:
            logger.error(f"Upload pipeline failed: {e}")
            await db.execute(
                sa_update(FileModel)
                .where(FileModel.id == file_record_id)
                .values(upload_status="failed")
            )
            await db.commit()
        finally:
            await tg.disconnect()



# ─── Routes ───────────────────────────────────────────────────

@router.post("/upload", response_model=UploadResponse)
async def upload_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    folder_id: Optional[str] = None,
    current_user: User = Depends(get_telegram_user),
    db: AsyncSession = Depends(get_db)
):
    """Upload a file to FTMS (Telegram storage)"""

    # Read file
    file_data = await file.read()
    file_size = len(file_data)

    # Check size limit
    if file_size > settings.MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Max: {settings.MAX_FILE_SIZE_GB}GB"
        )

    # Validate folder_id if provided
    parsed_folder_id = None
    if folder_id:
        try:
            parsed_folder_id = UUID(folder_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid folder_id format")

        folder_result = await db.execute(
            select(Folder).where(
                Folder.id == parsed_folder_id,
                Folder.user_id == current_user.id
            )
        )
        if not folder_result.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Folder not found")

    # Detect file type
    type_info = detect_file_type(file_data, file.filename)

    # Calculate checksum
    checksum = hashlib.sha256(file_data).hexdigest()

    # Create file record
    file_record = FileModel(
        user_id=current_user.id,
        folder_id=parsed_folder_id,
        original_name=file.filename,
        file_type=type_info["category"],
        mime_type=type_info["mime_type"],
        extension=type_info["extension"],
        size_bytes=file_size,
        is_chunked=file_size > settings.CHUNK_SIZE_BYTES,
        total_chunks=(
            (file_size // settings.CHUNK_SIZE_BYTES) + 1
            if file_size > settings.CHUNK_SIZE_BYTES else 1
        ),
        upload_status="uploading",
        checksum=checksum
    )
    db.add(file_record)
    await db.commit()
    await db.refresh(file_record)

    # Queue upload in background
    background_tasks.add_task(
        process_upload,
        file_data,
        str(file_record.id),
        current_user,
        settings.DATABASE_URL
    )

    return UploadResponse(
        file_id=file_record.id,
        status="uploading",
        message=f"Upload started for '{file.filename}'"
    )


@router.get("/list", response_model=FileListResponse)
async def list_files(
    folder_id: Optional[str] = None,
    file_type: Optional[str] = None,
    search: Optional[str] = None,
    is_favorite: Optional[bool] = None,
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List files with filters and pagination"""
    query = select(FileModel).where(
        FileModel.user_id == current_user.id,
        FileModel.upload_status == "complete"
    )

    # Apply filters
    if folder_id:
        if folder_id.lower() == "root":
            query = query.where(FileModel.folder_id == None)
        else:
            try:
                query = query.where(FileModel.folder_id == UUID(folder_id))
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid folder_id format")
    if file_type:
        query = query.where(FileModel.file_type == file_type)
    if is_favorite is not None:
        query = query.where(FileModel.is_favorite == is_favorite)
    if search:
        query = query.where(
            FileModel.original_name.ilike(f"%{search}%")
        )

    # Count total
    count_query = select(func.count()).select_from(query.subquery())
    total = await db.scalar(count_query)

    # Paginate
    offset = (page - 1) * limit
    query = query.order_by(FileModel.created_at.desc())
    query = query.offset(offset).limit(limit)

    result = await db.execute(query)
    files = result.scalars().all()

    return FileListResponse(
        files=[FileResponse.model_validate(f) for f in files],
        total=total,
        page=page,
        limit=limit,
        has_more=(offset + limit) < total
    )


@router.get("/status/{file_id}")
async def get_upload_status(
    file_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Check upload status of a file"""
    try:
        parsed_id = UUID(file_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid file_id format")

    result = await db.execute(
        select(FileModel).where(
            FileModel.id == parsed_id,
            FileModel.user_id == current_user.id
        )
    )
    file = result.scalar_one_or_none()
    if not file:
        raise HTTPException(status_code=404, detail="File not found")

    return {
        "file_id": file_id,
        "status": file.upload_status,
        "total_chunks": file.total_chunks,
        "is_chunked": file.is_chunked
    }


@router.get("/download/{file_id}")
async def download_file(
    file_id: str,
    current_user: User = Depends(get_telegram_user),
    db: AsyncSession = Depends(get_db)
):
    """Download a file from Telegram storage"""
    try:
        parsed_id = UUID(file_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid file_id format")

    result = await db.execute(
        select(FileModel).where(
            FileModel.id == parsed_id,
            FileModel.user_id == current_user.id,
            FileModel.upload_status == "complete"
        )
    )
    file_record = result.scalar_one_or_none()
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")

    tg = TelegramService(
        api_id=int(current_user.telegram_api_id),
        api_hash=current_user.telegram_api_hash,
        session_string=current_user.telegram_session
    )

    async def file_stream():
        try:
            if file_record.is_chunked:
                # Download and yield chunks in order
                for msg_id in sorted(file_record.telegram_message_ids):
                    async for block in tg.download_file_stream(
                        msg_id,
                        current_user.telegram_channel_id
                    ):
                        yield block
            else:
                async for block in tg.download_file_stream(
                    file_record.telegram_message_ids[0],
                    current_user.telegram_channel_id
                ):
                    yield block
        finally:
            await tg.disconnect()

    return StreamingResponse(
        file_stream(),
        media_type=file_record.mime_type or "application/octet-stream",
        headers={
            "Content-Disposition":
                f'attachment; filename="{file_record.original_name}"',
            "Content-Length": str(file_record.size_bytes)
        }
    )


@router.patch("/{file_id}", response_model=FileResponse)
async def update_file(
    file_id: UUID,
    data: FileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update file metadata (display name, tags, favorite status, folder)"""
    result = await db.execute(
        select(FileModel).where(
            FileModel.id == file_id,
            FileModel.user_id == current_user.id
        )
    )
    file_record = result.scalar_one_or_none()
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")

    # Update fields
    if data.display_name is not None:
        file_record.display_name = data.display_name
    if data.tags is not None:
        file_record.tags = data.tags
    if data.is_favorite is not None:
        file_record.is_favorite = data.is_favorite
    if data.folder_id is not None:
        # Verify folder exists and belongs to user
        if data.folder_id:
            folder_result = await db.execute(
                select(Folder).where(
                    Folder.id == data.folder_id,
                    Folder.user_id == current_user.id
                )
            )
            if not folder_result.scalar_one_or_none():
                raise HTTPException(status_code=400, detail="Invalid folder_id")
        file_record.folder_id = data.folder_id

    await db.commit()
    await db.refresh(file_record)
    return FileResponse.model_validate(file_record)


@router.delete("/{file_id}")
async def delete_file(
    file_id: UUID,
    current_user: User = Depends(get_telegram_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a file from database and Telegram channel"""
    result = await db.execute(
        select(FileModel).where(
            FileModel.id == file_id,
            FileModel.user_id == current_user.id
        )
    )
    file_record = result.scalar_one_or_none()
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found")

    tg = TelegramService(
        api_id=int(current_user.telegram_api_id),
        api_hash=current_user.telegram_api_hash,
        session_string=current_user.telegram_session
    )

    try:
        # Delete from Telegram
        if file_record.telegram_message_ids:
            await tg.delete_messages(
                file_record.telegram_message_ids,
                current_user.telegram_channel_id
            )
        if file_record.thumbnail_message_id:
            await tg.delete_messages(
                [file_record.thumbnail_message_id],
                current_user.telegram_channel_id
            )
    except Exception as e:
        logger.error(f"Error deleting from Telegram: {e}")

    # Update user storage stats
    await db.execute(
        update(User)
        .where(User.id == current_user.id)
        .values(
            storage_used_bytes=func.greatest(User.storage_used_bytes - file_record.size_bytes, 0),
            total_files=func.greatest(User.total_files - 1, 0)
        )
    )

    # Delete from DB
    await db.delete(file_record)
    await db.commit()

    return {"message": "File deleted successfully"}


# ─── Folder Routes ────────────────────────────────────────────

@router.post("/folders", response_model=FolderResponse)
async def create_folder(
    data: FolderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new folder"""
    # Calculate path
    path = f"/{data.name}"
    if data.parent_id:
        parent_result = await db.execute(
            select(Folder).where(
                Folder.id == data.parent_id,
                Folder.user_id == current_user.id
            )
        )
        parent = parent_result.scalar_one_or_none()
        if not parent:
            raise HTTPException(status_code=400, detail="Parent folder not found")
        path = f"{parent.path}/{data.name}"

    folder = Folder(
        user_id=current_user.id,
        name=data.name,
        parent_id=data.parent_id,
        path=path,
        color=data.color,
        icon=data.icon
    )
    db.add(folder)
    await db.commit()
    await db.refresh(folder)
    return FolderResponse.model_validate(folder)


@router.get("/folders", response_model=list[FolderResponse])
async def list_folders(
    parent_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List folders, optionally filtered by parent_id"""
    query = select(Folder).where(Folder.user_id == current_user.id)
    if parent_id:
        if parent_id.lower() == "root":
            query = query.where(Folder.parent_id == None)
        else:
            try:
                query = query.where(Folder.parent_id == UUID(parent_id))
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid parent_id format")
    
    result = await db.execute(query)
    folders = result.scalars().all()
    return [FolderResponse.model_validate(f) for f in folders]


@router.delete("/folders/{folder_id}")
async def delete_folder(
    folder_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a folder and its contents recursively"""
    result = await db.execute(
        select(Folder).where(
            Folder.id == folder_id,
            Folder.user_id == current_user.id
        )
    )
    folder = result.scalar_one_or_none()
    if not folder:
        raise HTTPException(status_code=404, detail="Folder not found")

    # Recursive check for child folders
    async def get_all_child_folder_ids(fid: UUID) -> list[UUID]:
        ids = [fid]
        res = await db.execute(select(Folder.id).where(Folder.parent_id == fid))
        child_ids = res.scalars().all()
        for cid in child_ids:
            ids.extend(await get_all_child_folder_ids(cid))
        return ids

    folder_ids = await get_all_child_folder_ids(folder_id)
    
    # Get files in these folders
    files_result = await db.execute(
        select(FileModel).where(
            FileModel.folder_id.in_(folder_ids),
            FileModel.user_id == current_user.id
        )
    )
    files = files_result.scalars().all()
    
    if files:
        # If user has connected telegram, we clean up
        if current_user.is_telegram_connected:
            tg = TelegramService(
                api_id=int(current_user.telegram_api_id),
                api_hash=current_user.telegram_api_hash,
                session_string=current_user.telegram_session
            )
            for file_record in files:
                try:
                    if file_record.telegram_message_ids:
                        await tg.delete_messages(
                            file_record.telegram_message_ids,
                            current_user.telegram_channel_id
                        )
                    if file_record.thumbnail_message_id:
                        await tg.delete_messages(
                            [file_record.thumbnail_message_id],
                            current_user.telegram_channel_id
                        )
                except Exception as e:
                    logger.error(f"Error deleting file {file_record.id} from Telegram: {e}")
                
                # Update user storage stats
                await db.execute(
                    update(User)
                    .where(User.id == current_user.id)
                    .values(
                        storage_used_bytes=func.greatest(User.storage_used_bytes - file_record.size_bytes, 0),
                        total_files=func.greatest(User.total_files - 1, 0)
                    )
                )
            await tg.disconnect()
        else:
            # If not connected to Telegram, just adjust DB counters
            for file_record in files:
                await db.execute(
                    update(User)
                    .where(User.id == current_user.id)
                    .values(
                        storage_used_bytes=func.greatest(User.storage_used_bytes - file_record.size_bytes, 0),
                        total_files=func.greatest(User.total_files - 1, 0)
                    )
                )

    await db.delete(folder)
    await db.commit()
    return {"message": "Folder and contents deleted successfully"}
