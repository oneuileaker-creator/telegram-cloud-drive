# app/services/ftms/detector.py

from pathlib import Path
from dataclasses import dataclass
from typing import Optional
import logging

logger = logging.getLogger(__name__)


# ─── File Category Constants ──────────────────────────────────

class FileCategory:
    IMAGE    = "image"
    VIDEO    = "video"
    AUDIO    = "audio"
    DOCUMENT = "document"
    CODE     = "code"
    ARCHIVE  = "archive"
    FONT     = "font"
    OTHER    = "other"


# ─── Complete MIME Map ────────────────────────────────────────

MIME_CATEGORY_MAP: dict[str, str] = {

    # ── Images ──────────────────────────────────────────────
    "image/jpeg":           FileCategory.IMAGE,
    "image/jpg":            FileCategory.IMAGE,
    "image/png":            FileCategory.IMAGE,
    "image/gif":            FileCategory.IMAGE,
    "image/webp":           FileCategory.IMAGE,
    "image/heic":           FileCategory.IMAGE,
    "image/heif":           FileCategory.IMAGE,
    "image/bmp":            FileCategory.IMAGE,
    "image/tiff":           FileCategory.IMAGE,
    "image/svg+xml":        FileCategory.IMAGE,
    "image/x-icon":         FileCategory.IMAGE,
    "image/avif":           FileCategory.IMAGE,
    "image/raw":            FileCategory.IMAGE,
    "image/x-raw":          FileCategory.IMAGE,
    "image/x-nikon-nef":    FileCategory.IMAGE,
    "image/x-canon-cr2":    FileCategory.IMAGE,

    # ── Videos ──────────────────────────────────────────────
    "video/mp4":            FileCategory.VIDEO,
    "video/x-matroska":     FileCategory.VIDEO,
    "video/avi":            FileCategory.VIDEO,
    "video/x-msvideo":      FileCategory.VIDEO,
    "video/quicktime":      FileCategory.VIDEO,
    "video/webm":           FileCategory.VIDEO,
    "video/x-flv":          FileCategory.VIDEO,
    "video/mpeg":           FileCategory.VIDEO,
    "video/3gpp":           FileCategory.VIDEO,
    "video/x-ms-wmv":       FileCategory.VIDEO,
    "video/ogg":            FileCategory.VIDEO,

    # ── Audio ────────────────────────────────────────────────
    "audio/mpeg":           FileCategory.AUDIO,
    "audio/mp3":            FileCategory.AUDIO,
    "audio/flac":           FileCategory.AUDIO,
    "audio/wav":            FileCategory.AUDIO,
    "audio/x-wav":          FileCategory.AUDIO,
    "audio/aac":            FileCategory.AUDIO,
    "audio/ogg":            FileCategory.AUDIO,
    "audio/x-m4a":          FileCategory.AUDIO,
    "audio/mp4":            FileCategory.AUDIO,
    "audio/opus":           FileCategory.AUDIO,
    "audio/webm":           FileCategory.AUDIO,
    "audio/x-ms-wma":       FileCategory.AUDIO,
    "audio/x-aiff":         FileCategory.AUDIO,

    # ── Documents ────────────────────────────────────────────
    "application/pdf":      FileCategory.DOCUMENT,
    "application/msword":   FileCategory.DOCUMENT,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
                            FileCategory.DOCUMENT,
    "application/vnd.ms-excel":
                            FileCategory.DOCUMENT,
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                            FileCategory.DOCUMENT,
    "application/vnd.ms-powerpoint":
                            FileCategory.DOCUMENT,
    "application/vnd.openxmlformats-officedocument.presentationml.presentation":
                            FileCategory.DOCUMENT,
    "application/vnd.oasis.opendocument.text":
                            FileCategory.DOCUMENT,
    "application/rtf":      FileCategory.DOCUMENT,
    "text/csv":             FileCategory.DOCUMENT,

    # ── Code / Text ──────────────────────────────────────────
    "text/plain":           FileCategory.CODE,
    "text/html":            FileCategory.CODE,
    "text/css":             FileCategory.CODE,
    "text/javascript":      FileCategory.CODE,
    "text/x-python":        FileCategory.CODE,
    "text/x-java":          FileCategory.CODE,
    "text/x-c":             FileCategory.CODE,
    "text/x-cpp":           FileCategory.CODE,
    "text/markdown":        FileCategory.CODE,
    "text/xml":             FileCategory.CODE,
    "application/json":     FileCategory.CODE,
    "application/javascript":
                            FileCategory.CODE,
    "application/typescript":
                            FileCategory.CODE,
    "application/xml":      FileCategory.CODE,
    "application/x-yaml":   FileCategory.CODE,
    "application/x-sh":     FileCategory.CODE,
    "application/x-php":    FileCategory.CODE,

    # ── Archives ─────────────────────────────────────────────
    "application/zip":      FileCategory.ARCHIVE,
    "application/x-rar-compressed":
                            FileCategory.ARCHIVE,
    "application/x-rar":    FileCategory.ARCHIVE,
    "application/x-7z-compressed":
                            FileCategory.ARCHIVE,
    "application/x-tar":    FileCategory.ARCHIVE,
    "application/gzip":     FileCategory.ARCHIVE,
    "application/x-bzip2":  FileCategory.ARCHIVE,
    "application/x-xz":     FileCategory.ARCHIVE,

    # ── Fonts ────────────────────────────────────────────────
    "font/ttf":             FileCategory.FONT,
    "font/otf":             FileCategory.FONT,
    "font/woff":            FileCategory.FONT,
    "font/woff2":           FileCategory.FONT,
    "application/x-font-ttf":
                            FileCategory.FONT,
}

# Extension fallback map (when magic fails)
EXTENSION_CATEGORY_MAP: dict[str, str] = {
    # Images
    "jpg": FileCategory.IMAGE,  "jpeg": FileCategory.IMAGE,
    "png": FileCategory.IMAGE,  "gif": FileCategory.IMAGE,
    "webp": FileCategory.IMAGE, "heic": FileCategory.IMAGE,
    "bmp": FileCategory.IMAGE,  "tiff": FileCategory.IMAGE,
    "svg": FileCategory.IMAGE,  "avif": FileCategory.IMAGE,
    "raw": FileCategory.IMAGE,  "nef": FileCategory.IMAGE,
    "cr2": FileCategory.IMAGE,
    # Videos
    "mp4": FileCategory.VIDEO,  "mkv": FileCategory.VIDEO,
    "avi": FileCategory.VIDEO,  "mov": FileCategory.VIDEO,
    "webm": FileCategory.VIDEO, "flv": FileCategory.VIDEO,
    "wmv": FileCategory.VIDEO,  "m4v": FileCategory.VIDEO,
    "3gp": FileCategory.VIDEO,
    # Audio
    "mp3": FileCategory.AUDIO,  "flac": FileCategory.AUDIO,
    "wav": FileCategory.AUDIO,  "aac": FileCategory.AUDIO,
    "ogg": FileCategory.AUDIO,  "m4a": FileCategory.AUDIO,
    "opus": FileCategory.AUDIO, "wma": FileCategory.AUDIO,
    "aiff": FileCategory.AUDIO,
    # Documents
    "pdf": FileCategory.DOCUMENT, "doc": FileCategory.DOCUMENT,
    "docx": FileCategory.DOCUMENT, "xls": FileCategory.DOCUMENT,
    "xlsx": FileCategory.DOCUMENT, "ppt": FileCategory.DOCUMENT,
    "pptx": FileCategory.DOCUMENT, "csv": FileCategory.DOCUMENT,
    "rtf": FileCategory.DOCUMENT,
    # Code
    "txt": FileCategory.CODE,   "py": FileCategory.CODE,
    "js": FileCategory.CODE,    "ts": FileCategory.CODE,
    "html": FileCategory.CODE,  "css": FileCategory.CODE,
    "json": FileCategory.CODE,  "xml": FileCategory.CODE,
    "yaml": FileCategory.CODE,  "yml": FileCategory.CODE,
    "md": FileCategory.CODE,    "sh": FileCategory.CODE,
    "java": FileCategory.CODE,  "cpp": FileCategory.CODE,
    "c": FileCategory.CODE,     "php": FileCategory.CODE,
    "go": FileCategory.CODE,    "rs": FileCategory.CODE,
    "kt": FileCategory.CODE,    "swift": FileCategory.CODE,
    # Archives
    "zip": FileCategory.ARCHIVE, "rar": FileCategory.ARCHIVE,
    "7z": FileCategory.ARCHIVE,  "tar": FileCategory.ARCHIVE,
    "gz": FileCategory.ARCHIVE,  "bz2": FileCategory.ARCHIVE,
    "xz": FileCategory.ARCHIVE,
    # Fonts
    "ttf": FileCategory.FONT,   "otf": FileCategory.FONT,
    "woff": FileCategory.FONT,  "woff2": FileCategory.FONT,
}


# ─── Detection Result ─────────────────────────────────────────

@dataclass
class DetectionResult:
    category: str
    mime_type: str
    extension: str
    is_previewable: bool
    is_streamable: bool
    icon: str
    color: str

    def to_dict(self) -> dict:
        return {
            "category": self.category,
            "mime_type": self.mime_type,
            "extension": self.extension,
            "is_previewable": self.is_previewable,
            "is_streamable": self.is_streamable,
            "icon": self.icon,
            "color": self.color
        }


# Category visual config
CATEGORY_CONFIG = {
    FileCategory.IMAGE:    {
        "icon": "image",
        "color": "#FF6B6B",
        "is_previewable": True,
        "is_streamable": False
    },
    FileCategory.VIDEO:    {
        "icon": "video",
        "color": "#4ECDC4",
        "is_previewable": True,
        "is_streamable": True
    },
    FileCategory.AUDIO:    {
        "icon": "music",
        "color": "#45B7D1",
        "is_previewable": True,
        "is_streamable": True
    },
    FileCategory.DOCUMENT: {
        "icon": "file-text",
        "color": "#96CEB4",
        "is_previewable": True,
        "is_streamable": False
    },
    FileCategory.CODE:     {
        "icon": "code",
        "color": "#A29BFE",
        "is_previewable": True,
        "is_streamable": False
    },
    FileCategory.ARCHIVE:  {
        "icon": "archive",
        "color": "#FFEAA7",
        "is_previewable": False,
        "is_streamable": False
    },
    FileCategory.FONT:     {
        "icon": "type",
        "color": "#FD79A8",
        "is_previewable": False,
        "is_streamable": False
    },
    FileCategory.OTHER:    {
        "icon": "file",
        "color": "#B2BEC3",
        "is_previewable": False,
        "is_streamable": False
    },
}


# ─── Detector Class ───────────────────────────────────────────

class FTMSDetector:

    @staticmethod
    def detect(file_data: bytes, filename: str) -> DetectionResult:
        """
        Detect file type using:
        1. python-magic (reads file bytes signature)
        2. Extension fallback
        """
        extension = Path(filename).suffix.lower().lstrip(".")
        mime_type = FTMSDetector._get_mime(file_data, extension)
        category = FTMSDetector._get_category(mime_type, extension)
        config = CATEGORY_CONFIG.get(category, CATEGORY_CONFIG[FileCategory.OTHER])

        return DetectionResult(
            category=category,
            mime_type=mime_type,
            extension=extension,
            is_previewable=config["is_previewable"],
            is_streamable=config["is_streamable"],
            icon=config["icon"],
            color=config["color"]
        )

    @staticmethod
    def _get_mime(file_data: bytes, extension: str) -> str:
        try:
            import magic
            return magic.from_buffer(file_data[:4096], mime=True)
        except Exception:
            # Extension fallback
            fallback_map = {
                "jpg": "image/jpeg",  "jpeg": "image/jpeg",
                "png": "image/png",   "gif": "image/gif",
                "mp4": "video/mp4",   "mp3": "audio/mpeg",
                "pdf": "application/pdf",
                "zip": "application/zip",
                "txt": "text/plain",  "json": "application/json",
            }
            return fallback_map.get(extension, "application/octet-stream")

    @staticmethod
    def _get_category(mime_type: str, extension: str) -> str:
        # Try MIME first
        if mime_type in MIME_CATEGORY_MAP:
            return MIME_CATEGORY_MAP[mime_type]
        # Try extension
        if extension in EXTENSION_CATEGORY_MAP:
            return EXTENSION_CATEGORY_MAP[extension]
        # Handle text/* generically
        if mime_type.startswith("text/"):
            return FileCategory.CODE
        if mime_type.startswith("image/"):
            return FileCategory.IMAGE
        if mime_type.startswith("video/"):
            return FileCategory.VIDEO
        if mime_type.startswith("audio/"):
            return FileCategory.AUDIO
        return FileCategory.OTHER

    @staticmethod
    def get_category_stats(categories: list[str]) -> dict:
        """Count files per category"""
        stats = {cat: 0 for cat in CATEGORY_CONFIG.keys()}
        for cat in categories:
            if cat in stats:
                stats[cat] += 1
        return stats
