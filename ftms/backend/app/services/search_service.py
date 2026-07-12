# app/services/search_service.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, and_, func, cast, String
from sqlalchemy.dialects.postgresql import ARRAY
from typing import Optional
from uuid import UUID
from datetime import datetime, timedelta

from app.database.models import File, Folder
import logging

logger = logging.getLogger(__name__)


class SearchService:

    @staticmethod
    async def search_files(
        db: AsyncSession,
        user_id: UUID,
        query: str = "",
        category: Optional[str] = None,
        folder_id: Optional[str] = None,
        tags: Optional[list[str]] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
        min_size: Optional[int] = None,
        max_size: Optional[int] = None,
        is_favorite: Optional[bool] = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
        page: int = 1,
        limit: int = 50
    ) -> dict:
        """
        Full search with filters.
        Searches: filename, tags, metadata
        """

        base_query = select(File).where(
            File.user_id == user_id,
            File.upload_status == "complete"
        )

        # ── Text Search ───────────────────────────────────────
        if query:
            base_query = base_query.where(
                or_(
                    File.original_name.ilike(f"%{query}%"),
                    File.display_name.ilike(f"%{query}%"),
                    cast(File.file_metadata, String).ilike(f"%{query}%")
                )
            )

        # ── Category Filter ───────────────────────────────────
        if category:
            base_query = base_query.where(
                File.file_type == category
            )

        # ── Folder Filter ─────────────────────────────────────
        if folder_id:
            base_query = base_query.where(
                File.folder_id == folder_id
            )

        # ── Tags Filter ───────────────────────────────────────
        if tags:
            for tag in tags:
                base_query = base_query.where(
                    File.tags.contains([tag])
                )

        # ── Date Range Filter ─────────────────────────────────
        if date_from:
            base_query = base_query.where(
                File.created_at >= date_from
            )
        if date_to:
            base_query = base_query.where(
                File.created_at <= date_to
            )

        # ── Size Filter ───────────────────────────────────────
        if min_size:
            base_query = base_query.where(
                File.size_bytes >= min_size
            )
        if max_size:
            base_query = base_query.where(
                File.size_bytes <= max_size
            )

        # ── Favorites Filter ──────────────────────────────────
        if is_favorite is not None:
            base_query = base_query.where(
                File.is_favorite == is_favorite
            )

        # ── Count Total ───────────────────────────────────────
        count_q = select(func.count()).select_from(base_query.subquery())
        total = await db.scalar(count_q)

        # ── Sort ──────────────────────────────────────────────
        sort_column = getattr(File, sort_by, File.created_at)
        if sort_order == "desc":
            base_query = base_query.order_by(sort_column.desc())
        else:
            base_query = base_query.order_by(sort_column.asc())

        # ── Paginate ──────────────────────────────────────────
        offset = (page - 1) * limit
        base_query = base_query.offset(offset).limit(limit)

        result = await db.execute(base_query)
        files = result.scalars().all()

        return {
            "files": files,
            "total": total,
            "page": page,
            "limit": limit,
            "has_more": (offset + limit) < total,
            "query": query
        }

    @staticmethod
    async def get_storage_stats(
        db: AsyncSession,
        user_id: UUID
    ) -> dict:
        """Get detailed storage statistics per category"""
        result = await db.execute(
            select(
                File.file_type,
                func.count(File.id).label("count"),
                func.sum(File.size_bytes).label("total_size")
            )
            .where(
                File.user_id == user_id,
                File.upload_status == "complete"
            )
            .group_by(File.file_type)
        )
        rows = result.all()

        stats = {}
        total_size = 0
        total_files = 0

        for row in rows:
            stats[row.file_type] = {
                "count": row.count,
                "size_bytes": int(row.total_size or 0)
            }
            total_size += int(row.total_size or 0)
            total_files += row.count

        return {
            "by_category": stats,
            "total_files": total_files,
            "total_size_bytes": total_size,
            "total_size_readable": SearchService._format_size(total_size)
        }

    @staticmethod
    async def get_recent_files(
        db: AsyncSession,
        user_id: UUID,
        days: int = 7,
        limit: int = 20
    ) -> list:
        since = datetime.utcnow() - timedelta(days=days)
        result = await db.execute(
            select(File)
            .where(
                File.user_id == user_id,
                File.upload_status == "complete",
                File.created_at >= since
            )
            .order_by(File.created_at.desc())
            .limit(limit)
        )
        return result.scalars().all()

    @staticmethod
    async def get_favorites(
        db: AsyncSession,
        user_id: UUID,
        page: int = 1,
        limit: int = 50
    ) -> dict:
        base = select(File).where(
            File.user_id == user_id,
            File.is_favorite == True,
            File.upload_status == "complete"
        )
        total = await db.scalar(
            select(func.count()).select_from(base.subquery())
        )
        result = await db.execute(
            base.order_by(File.created_at.desc())
            .offset((page - 1) * limit)
            .limit(limit)
        )
        return {
            "files": result.scalars().all(),
            "total": total,
            "page": page
        }

    @staticmethod
    def _format_size(size_bytes: int) -> str:
        for unit in ["B", "KB", "MB", "GB", "TB"]:
            if size_bytes < 1024:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024
        return f"{size_bytes:.2f} PB"
