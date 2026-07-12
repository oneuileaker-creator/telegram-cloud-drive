# app/database/schemas.py

from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID
from enum import Enum


class FileStatus(str, Enum):
    PENDING = "pending"
    UPLOADING = "uploading"
    COMPLETE = "complete"
    FAILED = "failed"


class FileType(str, Enum):
    IMAGE = "image"
    VIDEO = "video"
    AUDIO = "audio"
    DOCUMENT = "document"
    CODE = "code"
    ARCHIVE = "archive"
    OTHER = "other"


# ─── Auth Schemas ─────────────────────────────────────────────

class UserRegister(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: UUID
    email: str
    username: str
    is_telegram_connected: bool
    storage_used_bytes: int
    total_files: int
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse



# ─── Telegram Schemas ──────────────────────────────────────────

class TelegramConnect(BaseModel):
    api_id: int
    api_hash: str
    phone_number: str


class TelegramVerify(BaseModel):
    phone_number: str
    code: str
    phone_code_hash: str


class TelegramConnectResponse(BaseModel):
    status: str
    message: str
    phone_code_hash: Optional[str] = None
    requires_2fa: bool = False


# ─── Folder Schemas ────────────────────────────────────────────

class FolderCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    parent_id: Optional[UUID] = None
    color: str = "#4ECDC4"
    icon: str = "folder"


class FolderResponse(BaseModel):
    id: UUID
    name: str
    parent_id: Optional[UUID]
    path: str
    color: str
    icon: str
    created_at: datetime

    class Config:
        from_attributes = True


# ─── File Schemas ──────────────────────────────────────────────

class FileResponse(BaseModel):
    id: UUID
    original_name: str
    display_name: Optional[str]
    file_type: str
    mime_type: Optional[str]
    extension: Optional[str]
    size_bytes: int
    is_chunked: bool
    total_chunks: int
    upload_status: str
    tags: List[str]
    is_favorite: bool
    file_metadata: dict
    folder_id: Optional[UUID]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class FileListResponse(BaseModel):
    files: List[FileResponse]
    total: int
    page: int
    limit: int
    has_more: bool


class UploadResponse(BaseModel):
    file_id: UUID
    status: str
    message: str


class FileUpdate(BaseModel):
    display_name: Optional[str] = None
    tags: Optional[List[str]] = None
    is_favorite: Optional[bool] = None
    folder_id: Optional[UUID] = None
