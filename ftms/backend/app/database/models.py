# app/database/models.py

from sqlalchemy import (
    Column, String, Boolean, BigInteger,
    Integer, Text, DateTime, ForeignKey,
    JSON, ARRAY
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.connection import Base
import uuid


class User(Base):
    __tablename__ = "users"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)

    # Telegram credentials (stored encrypted)
    telegram_session = Column(Text, nullable=True)          # Telethon session string
    telegram_api_id = Column(String(50), nullable=True)
    telegram_api_hash = Column(String(100), nullable=True)
    telegram_channel_id = Column(BigInteger, nullable=True) # Private storage channel
    telegram_phone = Column(String(20), nullable=True)
    is_telegram_connected = Column(Boolean, default=False)

    # Storage stats
    storage_used_bytes = Column(BigInteger, default=0)
    total_files = Column(Integer, default=0)

    # Account status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    folders = relationship(
        "Folder",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    files = relationship(
        "File",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<User {self.email}>"


class Folder(Base):
    __tablename__ = "folders"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    name = Column(String(255), nullable=False)
    parent_id = Column(
        UUID(as_uuid=True),
        ForeignKey("folders.id", ondelete="CASCADE"),
        nullable=True    # NULL means root folder
    )
    path = Column(Text, nullable=False)   # e.g. /Photos/Vacation/2024
    color = Column(String(7), default="#4ECDC4")   # Hex color for UI
    icon = Column(String(50), default="folder")

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="folders")
    files = relationship(
        "File",
        back_populates="folder",
        cascade="all, delete-orphan"
    )
    parent = relationship(
        "Folder",
        remote_side=[id],
        back_populates="children"
    )
    children = relationship(
        "Folder",
        back_populates="parent",
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<Folder {self.path}>"


class File(Base):
    __tablename__ = "files"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    folder_id = Column(
        UUID(as_uuid=True),
        ForeignKey("folders.id", ondelete="SET NULL"),
        nullable=True
    )

    # File info
    original_name = Column(String(500), nullable=False)
    display_name = Column(String(500), nullable=True)
    file_type = Column(String(50), index=True)     # image/video/audio/document/etc
    mime_type = Column(String(100))
    extension = Column(String(20))
    size_bytes = Column(BigInteger, default=0)

    # Chunking info
    is_chunked = Column(Boolean, default=False)
    total_chunks = Column(Integer, default=1)
    telegram_message_ids = Column(ARRAY(BigInteger), default=[])
    thumbnail_message_id = Column(BigInteger, nullable=True)

    # Metadata (EXIF, duration, dimensions, etc)
    file_metadata = Column(JSON, default={})

    # Status
    upload_status = Column(
        String(20),
        default="pending"
    )
    # pending / uploading / complete / failed / deleting

    # Search & Organization
    tags = Column(ARRAY(String), default=[])
    is_favorite = Column(Boolean, default=False)
    is_encrypted = Column(Boolean, default=False)

    # Checksum for integrity
    checksum = Column(String(64), nullable=True)   # SHA256

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="files")
    folder = relationship("Folder", back_populates="files")
    chunks = relationship(
        "FileChunk",
        back_populates="file",
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<File {self.original_name}>"


class FileChunk(Base):
    __tablename__ = "file_chunks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    file_id = Column(
        UUID(as_uuid=True),
        ForeignKey("files.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    chunk_index = Column(Integer, nullable=False)
    chunk_size = Column(BigInteger)
    telegram_message_id = Column(BigInteger, nullable=True)
    upload_status = Column(String(20), default="pending")
    checksum = Column(String(64))    # SHA256 of this chunk

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    file = relationship("File", back_populates="chunks")

    def __repr__(self):
        return f"<FileChunk {self.file_id} chunk {self.chunk_index}>"


class TelegramSession(Base):
    """Store multiple Telegram sessions per user"""
    __tablename__ = "telegram_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )
    session_name = Column(String(100), default="default")
    session_string = Column(Text, nullable=False)     # Encrypted session
    phone_number = Column(String(20))
    is_active = Column(Boolean, default=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_used = Column(DateTime(timezone=True), onupdate=func.now())
