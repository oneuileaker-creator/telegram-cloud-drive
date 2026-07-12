# app/utils/helpers.py

import mimetypes
import os
from typing import Dict, List

# Optional import for magic to support platforms without libmagic (e.g. Windows)
try:
    import magic
    HAS_MAGIC = True
except Exception:
    HAS_MAGIC = False



def split_into_chunks(file_data: bytes, chunk_size: int) -> List[bytes]:
    """Split bytes data into a list of smaller bytes chunks"""
    chunks = []
    for i in range(0, len(file_data), chunk_size):
        chunks.append(file_data[i:i + chunk_size])
    return chunks


def detect_file_type(file_data: bytes, filename: str) -> Dict[str, str]:
    """
    Detect mime type and classify file into categories (image, video, audio, document, etc.)
    using magic bytes and fallbacks.
    """
    mime_type = None
    extension = os.path.splitext(filename)[1].lower() if filename else ""
    category = "other"

    # Try to guess mime type from file content header using python-magic
    if HAS_MAGIC:
        try:
            mime_type = magic.from_buffer(file_data[:2048], mime=True)
        except Exception:
            pass


    # Fallback to extension if magic fails or returns generic octet-stream
    if not mime_type or mime_type == "application/octet-stream":
        mime_type, _ = mimetypes.guess_type(filename or "")
        if not mime_type:
            mime_type = "application/octet-stream"

    # Determine category based on mime type or extension
    if mime_type.startswith("image/"):
        category = "image"
    elif mime_type.startswith("video/"):
        category = "video"
    elif mime_type.startswith("audio/"):
        category = "audio"
    elif mime_type.startswith("text/") or extension in [".txt", ".pdf", ".docx", ".xlsx", ".pptx", ".md"]:
        category = "document"
    elif extension in [".py", ".js", ".ts", ".html", ".css", ".json", ".xml", ".sh", ".bat"]:
        category = "code"
    elif extension in [".zip", ".tar", ".gz", ".rar", ".7z"]:
        category = "archive"

    return {
        "mime_type": mime_type,
        "extension": extension.replace(".", ""),
        "category": category
    }


def format_file_size(size_bytes: int) -> str:
    """Format file size in bytes to human readable format (KB, MB, GB, etc.)"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"
