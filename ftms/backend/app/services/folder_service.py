# app/services/folder_service.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, func
from typing import Optional
from uuid import UUID

from app.database.models import Folder, File
from app.database.schemas import FolderCreate
import logging

logger = logging.getLogger(__name__)


class FolderService:

    @staticmethod
    async def create_folder(
        db: AsyncSession,
        user_id: UUID,
        data: FolderCreate
    ) -> Folder:
        """Create a new folder"""

        # Check if parent exists (if specified)
        parent_path = "/"
        if data.parent_id:
            result = await db.execute(
                select(Folder).where(
                    Folder.id == data.parent_id,
                    Folder.user_id == user_id
                )
            )
            parent = result.scalar_one_or_none()
            if not parent:
                raise ValueError("Parent folder not found")
            parent_path = parent.path

        # Build full path
        clean_name = data.name.strip().replace("/", "_")
        path = f"{parent_path.rstrip('/')}/{clean_name}"

        # Check duplicate at same level
        result = await db.execute(
            select(Folder).where(
                Folder.user_id == user_id,
                Folder.path == path
            )
        )
        if result.scalar_one_or_none():
            raise ValueError(f"Folder '{clean_name}' already exists here")

        folder = Folder(
            user_id=user_id,
            name=clean_name,
            parent_id=data.parent_id,
            path=path,
            color=data.color,
            icon=data.icon
        )
        db.add(folder)
        await db.commit()
        await db.refresh(folder)

        logger.info(f"✅ Folder created: {path}")
        return folder

    @staticmethod
    async def get_folder_tree(
        db: AsyncSession,
        user_id: UUID,
        parent_id: Optional[UUID] = None
    ) -> list[dict]:
        """
        Get folder tree (recursive structure)
        Returns folders at current level with children count
        """
        result = await db.execute(
            select(Folder).where(
                Folder.user_id == user_id,
                Folder.parent_id == parent_id
            ).order_by(Folder.name)
        )
        folders = result.scalars().all()

        tree = []
        for folder in folders:
            # Count children
            children_count = await db.scalar(
                select(func.count()).where(
                    Folder.parent_id == folder.id
                )
            )
            # Count files
            file_count = await db.scalar(
                select(func.count()).where(
                    File.folder_id == folder.id,
                    File.upload_status == "complete"
                )
            )
            tree.append({
                "id": str(folder.id),
                "name": folder.name,
                "path": folder.path,
                "parent_id": str(folder.parent_id) if folder.parent_id else None,
                "color": folder.color,
                "icon": folder.icon,
                "children_count": children_count,
                "file_count": file_count,
                "created_at": folder.created_at.isoformat()
            })

        return tree

    @staticmethod
    async def get_folder_by_path(
        db: AsyncSession,
        user_id: UUID,
        path: str
    ) -> Optional[Folder]:
        result = await db.execute(
            select(Folder).where(
                Folder.user_id == user_id,
                Folder.path == path
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def rename_folder(
        db: AsyncSession,
        user_id: UUID,
        folder_id: UUID,
        new_name: str
    ) -> Folder:
        result = await db.execute(
            select(Folder).where(
                Folder.id == folder_id,
                Folder.user_id == user_id
            )
        )
        folder = result.scalar_one_or_none()
        if not folder:
            raise ValueError("Folder not found")

        old_path = folder.path
        parent_path = "/".join(old_path.split("/")[:-1]) or "/"
        new_path = f"{parent_path.rstrip('/')}/{new_name.strip()}"

        # Update this folder
        folder.name = new_name.strip()
        folder.path = new_path

        # Update all children paths
        result = await db.execute(
            select(Folder).where(
                Folder.user_id == user_id,
                Folder.path.like(f"{old_path}/%")
            )
        )
        children = result.scalars().all()
        for child in children:
            child.path = child.path.replace(old_path, new_path, 1)

        await db.commit()
        await db.refresh(folder)
        return folder

    @staticmethod
    async def delete_folder(
        db: AsyncSession,
        user_id: UUID,
        folder_id: UUID,
        delete_files: bool = False
    ) -> dict:
        """
        Delete folder.
        delete_files=True  → also delete all files inside
        delete_files=False → move files to root (no folder)
        """
        result = await db.execute(
            select(Folder).where(
                Folder.id == folder_id,
                Folder.user_id == user_id
            )
        )
        folder = result.scalar_one_or_none()
        if not folder:
            raise ValueError("Folder not found")

        if not delete_files:
            # Move files to root
            await db.execute(
                update(File)
                .where(File.folder_id == folder_id)
                .values(folder_id=None)
            )

        # Delete folder (cascade deletes children)
        await db.execute(
            delete(Folder).where(Folder.id == folder_id)
        )
        await db.commit()

        return {"deleted": str(folder_id), "path": folder.path}

    @staticmethod
    async def move_folder(
        db: AsyncSession,
        user_id: UUID,
        folder_id: UUID,
        new_parent_id: Optional[UUID]
    ) -> Folder:
        """Move folder to a different parent"""
        result = await db.execute(
            select(Folder).where(
                Folder.id == folder_id,
                Folder.user_id == user_id
            )
        )
        folder = result.scalar_one_or_none()
        if not folder:
            raise ValueError("Folder not found")

        new_parent_path = "/"
        if new_parent_id:
            result = await db.execute(
                select(Folder).where(
                    Folder.id == new_parent_id,
                    Folder.user_id == user_id
                )
            )
            new_parent = result.scalar_one_or_none()
            if not new_parent:
                raise ValueError("Destination folder not found")
            new_parent_path = new_parent.path

        old_path = folder.path
        new_path = f"{new_parent_path.rstrip('/')}/{folder.name}"

        folder.parent_id = new_parent_id
        folder.path = new_path

        # Update children paths
        result = await db.execute(
            select(Folder).where(
                Folder.user_id == user_id,
                Folder.path.like(f"{old_path}/%")
            )
        )
        for child in result.scalars().all():
            child.path = child.path.replace(old_path, new_path, 1)

        await db.commit()
        await db.refresh(folder)
        return folder
