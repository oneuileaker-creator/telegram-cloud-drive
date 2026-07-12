Phase 2: FTMS Core
File Type System + Thumbnails + Metadata + Folders + Search
Step 1: Update Requirements
txt

# Add to requirements.txt

# Image processing
Pillow==10.2.0

# Video processing
ffmpeg-python==0.2.0

# Audio metadata
mutagen==1.47.0

# Document processing
pypdf==4.0.0
python-docx==1.1.0
openpyxl==3.1.2

# File type detection
python-magic==0.4.27

# Search
sqlalchemy[asyncio]==2.0.25
Bash

pip install Pillow ffmpeg-python mutagen pypdf python-docx openpyxl python-magic
Step 2: Full Project Structure for Phase 2
text

backend/
├── app/
│   ├── services/
│   │   ├── ftms/
│   │   │   ├── __init__.py
│   │   │   ├── detector.py         # File type detection
│   │   │   ├── thumbnail.py        # Thumbnail generation
│   │   │   ├── metadata.py         # Metadata extraction
│   │   │   └── router.py           # FTMS main router
│   │   ├── chunk_service.py        # Chunking (enhanced)
│   │   ├── folder_service.py       # Folder operations
│   │   └── search_service.py       # Search system
│   ├── api/
│   │   └── routes/
│   │       ├── folders.py          # Folder routes
│   │       ├── media.py            # Photos/Videos routes
│   │       └── search.py           # Search routes
Bash

# Create new folders and files
mkdir -p app/services/ftms
touch app/services/ftms/__init__.py
touch app/services/ftms/detector.py
touch app/services/ftms/thumbnail.py
touch app/services/ftms/metadata.py
touch app/services/ftms/router.py
touch app/services/chunk_service.py
touch app/services/folder_service.py
touch app/services/search_service.py
touch app/api/routes/folders.py
touch app/api/routes/media.py
touch app/api/routes/search.py
Step 3: FTMS Detector
Python

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
Step 4: Thumbnail Generator
Python

# app/services/ftms/thumbnail.py

import io
import logging
from typing import Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)

THUMBNAIL_SIZE = (400, 400)     # Max dimensions
THUMBNAIL_QUALITY = 75          # JPEG quality


@dataclass
class ThumbnailResult:
    data: bytes
    width: int
    height: int
    format: str = "JPEG"


class ThumbnailGenerator:

    # ─── Main Entry Point ─────────────────────────────────────

    @staticmethod
    async def generate(
        file_data: bytes,
        category: str,
        mime_type: str,
        filename: str
    ) -> Optional[ThumbnailResult]:
        """
        Generate thumbnail based on file category.
        Returns None if thumbnail not possible.
        """
        try:
            if category == "image":
                return await ThumbnailGenerator._from_image(
                    file_data, mime_type
                )
            elif category == "video":
                return await ThumbnailGenerator._from_video(file_data)
            elif category == "audio":
                return await ThumbnailGenerator._from_audio(file_data)
            elif category == "document":
                return await ThumbnailGenerator._from_document(
                    file_data, mime_type
                )
            elif category == "code":
                return await ThumbnailGenerator._from_code(
                    file_data, filename
                )
            else:
                return None
        except Exception as e:
            logger.warning(f"Thumbnail generation failed ({category}): {e}")
            return None

    # ─── Image Thumbnail ──────────────────────────────────────

    @staticmethod
    async def _from_image(
        file_data: bytes,
        mime_type: str
    ) -> Optional[ThumbnailResult]:
        from PIL import Image, ImageOps
        import asyncio

        def _process():
            img = Image.open(io.BytesIO(file_data))

            # Fix orientation (EXIF)
            img = ImageOps.exif_transpose(img)

            # Convert to RGB if needed (PNG RGBA, etc)
            if img.mode not in ("RGB", "L"):
                img = img.convert("RGB")

            # Resize keeping aspect ratio
            img.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)

            # Save as JPEG
            buf = io.BytesIO()
            img.save(buf, format="JPEG", quality=THUMBNAIL_QUALITY, optimize=True)
            return buf.getvalue(), img.width, img.height

        # Run in thread pool (PIL is sync)
        loop = __import__("asyncio").get_event_loop()
        thumb_bytes, w, h = await loop.run_in_executor(None, _process)

        return ThumbnailResult(data=thumb_bytes, width=w, height=h)

    # ─── Video Thumbnail ──────────────────────────────────────

    @staticmethod
    async def _from_video(
        file_data: bytes
    ) -> Optional[ThumbnailResult]:
        import asyncio
        import tempfile
        import os

        # ffmpeg needs a real file path
        with tempfile.NamedTemporaryFile(
            suffix=".mp4",
            delete=False
        ) as tmp_in:
            tmp_in.write(file_data)
            tmp_in_path = tmp_in.name

        tmp_out_path = tmp_in_path + "_thumb.jpg"

        try:
            # Run ffmpeg async
            proc = await asyncio.create_subprocess_exec(
                "ffmpeg",
                "-i", tmp_in_path,
                "-ss", "00:00:01",          # Seek to 1 second
                "-vframes", "1",             # Capture 1 frame
                "-vf", f"scale={THUMBNAIL_SIZE[0]}:{THUMBNAIL_SIZE[1]}:force_original_aspect_ratio=decrease",
                "-q:v", "3",                 # Quality
                "-y",                        # Overwrite
                tmp_out_path,
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL
            )
            await proc.wait()

            if not os.path.exists(tmp_out_path):
                return None

            with open(tmp_out_path, "rb") as f:
                thumb_bytes = f.read()

            # Get dimensions
            from PIL import Image
            img = Image.open(io.BytesIO(thumb_bytes))
            return ThumbnailResult(
                data=thumb_bytes,
                width=img.width,
                height=img.height
            )

        finally:
            # Cleanup temp files
            for path in [tmp_in_path, tmp_out_path]:
                try:
                    os.unlink(path)
                except Exception:
                    pass

    # ─── Audio Thumbnail (Album Art) ──────────────────────────

    @staticmethod
    async def _from_audio(
        file_data: bytes
    ) -> Optional[ThumbnailResult]:
        import asyncio

        def _extract_art():
            from mutagen import File as MutagenFile
            from mutagen.id3 import ID3
            from mutagen.mp4 import MP4

            audio_file = MutagenFile(io.BytesIO(file_data))
            if not audio_file:
                return None

            art_data = None

            # MP3 ID3 tags
            if hasattr(audio_file, 'tags') and audio_file.tags:
                for key in audio_file.tags.keys():
                    if key.startswith('APIC'):
                        art_data = audio_file.tags[key].data
                        break

            # MP4/M4A
            if not art_data and isinstance(audio_file, MP4):
                covr = audio_file.tags.get('covr')
                if covr:
                    art_data = bytes(covr[0])

            if not art_data:
                return None

            # Resize album art
            from PIL import Image
            img = Image.open(io.BytesIO(art_data))
            if img.mode != "RGB":
                img = img.convert("RGB")
            img.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            img.save(buf, format="JPEG", quality=THUMBNAIL_QUALITY)
            return buf.getvalue(), img.width, img.height

        loop = __import__("asyncio").get_event_loop()
        result = await loop.run_in_executor(None, _extract_art)

        if not result:
            return None

        thumb_bytes, w, h = result
        return ThumbnailResult(data=thumb_bytes, width=w, height=h)

    # ─── Document Thumbnail (PDF First Page) ──────────────────

    @staticmethod
    async def _from_document(
        file_data: bytes,
        mime_type: str
    ) -> Optional[ThumbnailResult]:
        import asyncio

        if mime_type != "application/pdf":
            return None

        def _render_pdf():
            try:
                import fitz  # PyMuPDF
                doc = fitz.open(stream=file_data, filetype="pdf")
                page = doc[0]
                # Render at 150 DPI
                mat = fitz.Matrix(150 / 72, 150 / 72)
                pix = page.get_pixmap(matrix=mat)
                img_data = pix.tobytes("jpeg")

                from PIL import Image
                img = Image.open(io.BytesIO(img_data))
                img.thumbnail(THUMBNAIL_SIZE, Image.Resampling.LANCZOS)
                buf = io.BytesIO()
                img.save(buf, format="JPEG", quality=THUMBNAIL_QUALITY)
                return buf.getvalue(), img.width, img.height
            except ImportError:
                logger.warning("PyMuPDF not installed, skipping PDF thumbnail")
                return None

        loop = __import__("asyncio").get_event_loop()
        result = await loop.run_in_executor(None, _render_pdf)

        if not result:
            return None

        thumb_bytes, w, h = result
        return ThumbnailResult(data=thumb_bytes, width=w, height=h)

    # ─── Code Thumbnail (Syntax Preview Card) ─────────────────

    @staticmethod
    async def _from_code(
        file_data: bytes,
        filename: str
    ) -> Optional[ThumbnailResult]:
        """Generate a simple preview card for code files"""
        import asyncio

        def _render_code():
            try:
                from PIL import Image, ImageDraw, ImageFont
                from pathlib import Path

                text = file_data[:1000].decode("utf-8", errors="replace")
                lines = text.split("\n")[:20]

                # Create dark background card
                img = Image.new("RGB", THUMBNAIL_SIZE, color="#1E1E2E")
                draw = ImageDraw.Draw(img)

                # Try to load monospace font
                try:
                    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 12)
                    title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 14)
                except Exception:
                    font = ImageFont.load_default()
                    title_font = font

                # Draw filename header bar
                draw.rectangle([0, 0, THUMBNAIL_SIZE[0], 30], fill="#313244")
                draw.text((10, 8), Path(filename).name, font=title_font, fill="#CDD6F4")

                # Draw code lines
                y = 40
                for line in lines:
                    if y > THUMBNAIL_SIZE[1] - 20:
                        break
                    draw.text((10, y), line[:50], font=font, fill="#CDD6F4")
                    y += 16

                buf = io.BytesIO()
                img.save(buf, format="JPEG", quality=THUMBNAIL_QUALITY)
                return buf.getvalue(), img.width, img.height

            except Exception as e:
                logger.warning(f"Code thumbnail error: {e}")
                return None

        loop = __import__("asyncio").get_event_loop()
        result = await loop.run_in_executor(None, _render_code)

        if not result:
            return None

        thumb_bytes, w, h = result
        return ThumbnailResult(data=thumb_bytes, width=w, height=h)
Step 5: Metadata Extractor
Python

# app/services/ftms/metadata.py

import io
import logging
from typing import Optional
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class ImageMetadata:
    width: int = 0
    height: int = 0
    mode: str = ""
    format: str = ""
    has_transparency: bool = False
    exif: dict = field(default_factory=dict)
    gps: Optional[dict] = None
    camera: Optional[str] = None
    taken_at: Optional[str] = None
    iso: Optional[int] = None
    aperture: Optional[str] = None
    shutter_speed: Optional[str] = None


@dataclass
class VideoMetadata:
    duration_seconds: float = 0.0
    width: int = 0
    height: int = 0
    fps: float = 0.0
    bitrate: int = 0
    video_codec: str = ""
    audio_codec: str = ""
    has_audio: bool = False


@dataclass
class AudioMetadata:
    duration_seconds: float = 0.0
    bitrate: int = 0
    sample_rate: int = 0
    channels: int = 0
    codec: str = ""
    title: Optional[str] = None
    artist: Optional[str] = None
    album: Optional[str] = None
    year: Optional[str] = None
    genre: Optional[str] = None
    track_number: Optional[str] = None
    has_cover_art: bool = False


@dataclass
class DocumentMetadata:
    page_count: int = 0
    word_count: int = 0
    title: Optional[str] = None
    author: Optional[str] = None
    created_at: Optional[str] = None
    modified_at: Optional[str] = None
    has_images: bool = False


@dataclass
class ArchiveMetadata:
    file_count: int = 0
    total_uncompressed_bytes: int = 0
    compression_ratio: float = 0.0
    file_list: list = field(default_factory=list)


class MetadataExtractor:

    # ─── Main Entry ───────────────────────────────────────────

    @staticmethod
    async def extract(
        file_data: bytes,
        category: str,
        mime_type: str
    ) -> dict:
        """
        Extract metadata from file based on category.
        Always returns a dict (empty if unsupported).
        """
        try:
            if category == "image":
                return await MetadataExtractor._image(file_data)
            elif category == "video":
                return await MetadataExtractor._video(file_data)
            elif category == "audio":
                return await MetadataExtractor._audio(file_data)
            elif category == "document":
                return await MetadataExtractor._document(file_data, mime_type)
            elif category == "archive":
                return await MetadataExtractor._archive(file_data, mime_type)
            elif category == "code":
                return await MetadataExtractor._code(file_data)
            return {}
        except Exception as e:
            logger.warning(f"Metadata extraction failed ({category}): {e}")
            return {}

    # ─── Image Metadata ───────────────────────────────────────

    @staticmethod
    async def _image(file_data: bytes) -> dict:
        import asyncio

        def _process():
            from PIL import Image
            from PIL.ExifTags import TAGS, GPSTAGS

            result = ImageMetadata()

            try:
                img = Image.open(io.BytesIO(file_data))
                result.width = img.width
                result.height = img.height
                result.mode = img.mode
                result.format = img.format or ""
                result.has_transparency = img.mode in ("RGBA", "LA", "PA")

                # Extract EXIF
                exif_data = img._getexif()
                if exif_data:
                    for tag_id, value in exif_data.items():
                        tag = TAGS.get(tag_id, tag_id)

                        # GPS data
                        if tag == "GPSInfo":
                            gps = {}
                            for gps_id, gps_val in value.items():
                                gps[GPSTAGS.get(gps_id, gps_id)] = str(gps_val)
                            result.gps = gps
                            continue

                        # Camera info
                        if tag in ("Make", "Model"):
                            result.camera = (result.camera or "") + str(value) + " "

                        # Shot info
                        if tag == "DateTimeOriginal":
                            result.taken_at = str(value)
                        if tag == "ISOSpeedRatings":
                            result.iso = int(value)
                        if tag == "FNumber":
                            result.aperture = f"f/{float(value):.1f}"
                        if tag == "ExposureTime":
                            result.shutter_speed = f"1/{int(1/float(value))}s" if value < 1 else f"{float(value)}s"

                        # Store clean EXIF (skip binary)
                        if isinstance(value, (str, int, float)):
                            result.exif[tag] = value

            except Exception as e:
                logger.debug(f"Image metadata partial error: {e}")

            return result.__dict__

        loop = __import__("asyncio").get_event_loop()
        return await loop.run_in_executor(None, _process)

    # ─── Video Metadata ───────────────────────────────────────

    @staticmethod
    async def _video(file_data: bytes) -> dict:
        import asyncio
        import tempfile
        import os
        import json

        result = VideoMetadata()

        with tempfile.NamedTemporaryFile(
            suffix=".mp4",
            delete=False
        ) as tmp:
            tmp.write(file_data)
            tmp_path = tmp.name

        try:
            proc = await asyncio.create_subprocess_exec(
                "ffprobe",
                "-v", "quiet",
                "-print_format", "json",
                "-show_streams",
                "-show_format",
                tmp_path,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            stdout, _ = await proc.communicate()
            probe = json.loads(stdout)

            fmt = probe.get("format", {})
            result.duration_seconds = float(fmt.get("duration", 0))
            result.bitrate = int(fmt.get("bit_rate", 0))

            for stream in probe.get("streams", []):
                if stream.get("codec_type") == "video":
                    result.width = stream.get("width", 0)
                    result.height = stream.get("height", 0)
                    result.video_codec = stream.get("codec_name", "")
                    fps_str = stream.get("r_frame_rate", "0/1")
                    try:
                        num, den = fps_str.split("/")
                        result.fps = round(int(num) / int(den), 2)
                    except Exception:
                        result.fps = 0.0

                elif stream.get("codec_type") == "audio":
                    result.audio_codec = stream.get("codec_name", "")
                    result.has_audio = True

        except Exception as e:
            logger.warning(f"Video metadata error: {e}")
        finally:
            try:
                os.unlink(tmp_path)
            except Exception:
                pass

        return result.__dict__

    # ─── Audio Metadata ───────────────────────────────────────

    @staticmethod
    async def _audio(file_data: bytes) -> dict:
        import asyncio

        def _process():
            from mutagen import File as MutagenFile

            result = AudioMetadata()
            audio = MutagenFile(io.BytesIO(file_data))

            if not audio:
                return result.__dict__

            # Duration & technical info
            if audio.info:
                result.duration_seconds = round(audio.info.length, 2)
                result.bitrate = getattr(audio.info, "bitrate", 0)
                result.sample_rate = getattr(audio.info, "sample_rate", 0)
                result.channels = getattr(audio.info, "channels", 0)

            # Tags
            tags = audio.tags
            if tags:
                def get_tag(*keys):
                    for key in keys:
                        val = tags.get(key)
                        if val:
                            return str(val[0]) if isinstance(val, list) else str(val)
                    return None

                result.title = get_tag("TIT2", "title", "\xa9nam")
                result.artist = get_tag("TPE1", "artist", "\xa9ART")
                result.album = get_tag("TALB", "album", "\xa9alb")
                result.year = get_tag("TDRC", "date", "\xa9day")
                result.genre = get_tag("TCON", "genre", "\xa9gen")
                result.track_number = get_tag("TRCK", "tracknumber", "trkn")

                # Check for cover art
                for key in tags.keys():
                    if key.startswith("APIC") or key == "covr":
                        result.has_cover_art = True
                        break

            return result.__dict__

        loop = __import__("asyncio").get_event_loop()
        return await loop.run_in_executor(None, _process)

    # ─── Document Metadata ────────────────────────────────────

    @staticmethod
    async def _document(file_data: bytes, mime_type: str) -> dict:
        import asyncio

        result = DocumentMetadata()

        def _process_pdf():
            from pypdf import PdfReader
            reader = PdfReader(io.BytesIO(file_data))
            result.page_count = len(reader.pages)

            info = reader.metadata
            if info:
                result.title = info.get("/Title")
                result.author = info.get("/Author")
                result.created_at = str(info.get("/CreationDate", ""))
                result.modified_at = str(info.get("/ModDate", ""))

            # Count words from first 5 pages
            text = ""
            for page in reader.pages[:5]:
                text += page.extract_text() or ""
            result.word_count = len(text.split())
            return result.__dict__

        def _process_docx():
            from docx import Document
            doc = Document(io.BytesIO(file_data))
            result.page_count = 1         # python-docx doesn't give page count
            result.title = doc.core_properties.title
            result.author = doc.core_properties.author
            result.created_at = str(doc.core_properties.created or "")
            result.modified_at = str(doc.core_properties.modified or "")
            text = "\n".join([p.text for p in doc.paragraphs])
            result.word_count = len(text.split())
            result.has_images = len(doc.inline_shapes) > 0
            return result.__dict__

        def _process_xlsx():
            from openpyxl import load_workbook
            wb = load_workbook(io.BytesIO(file_data), read_only=True, data_only=True)
            result.page_count = len(wb.sheetnames)
            return result.__dict__

        loop = __import__("asyncio").get_event_loop()

        try:
            if mime_type == "application/pdf":
                return await loop.run_in_executor(None, _process_pdf)
            elif "wordprocessing" in mime_type or mime_type == "application/msword":
                return await loop.run_in_executor(None, _process_docx)
            elif "spreadsheet" in mime_type or "excel" in mime_type:
                return await loop.run_in_executor(None, _process_xlsx)
        except Exception as e:
            logger.warning(f"Document metadata error: {e}")

        return result.__dict__

    # ─── Archive Metadata ─────────────────────────────────────

    @staticmethod
    async def _archive(file_data: bytes, mime_type: str) -> dict:
        import asyncio

        def _process():
            result = ArchiveMetadata()

            try:
                if "zip" in mime_type:
                    import zipfile
                    with zipfile.ZipFile(io.BytesIO(file_data)) as zf:
                        infos = zf.infolist()
                        result.file_count = len(infos)
                        result.total_uncompressed_bytes = sum(
                            i.file_size for i in infos
                        )
                        result.file_list = [i.filename for i in infos[:100]]
                        if result.total_uncompressed_bytes > 0:
                            result.compression_ratio = round(
                                len(file_data) / result.total_uncompressed_bytes, 2
                            )

                elif "x-tar" in mime_type or "gzip" in mime_type:
                    import tarfile
                    with tarfile.open(fileobj=io.BytesIO(file_data)) as tf:
                        members = tf.getmembers()
                        result.file_count = len(members)
                        result.file_list = [m.name for m in members[:100]]

            except Exception as e:
                logger.debug(f"Archive read error: {e}")

            return result.__dict__

        loop = __import__("asyncio").get_event_loop()
        return await loop.run_in_executor(None, _process)

    # ─── Code Metadata ────────────────────────────────────────

    @staticmethod
    async def _code(file_data: bytes) -> dict:
        try:
            text = file_data.decode("utf-8", errors="replace")
            lines = text.split("\n")
            return {
                "line_count": len(lines),
                "char_count": len(text),
                "word_count": len(text.split()),
                "blank_lines": sum(1 for l in lines if not l.strip()),
                "preview": "\n".join(lines[:10])
            }
        except Exception:
            return {}
Step 6: FTMS Router (Main Orchestrator)
Python

# app/services/ftms/router.py

import hashlib
import logging
from dataclasses import dataclass
from typing import Optional

from app.services.ftms.detector import FTMSDetector, DetectionResult
from app.services.ftms.thumbnail import ThumbnailGenerator, ThumbnailResult
from app.services.ftms.metadata import MetadataExtractor

logger = logging.getLogger(__name__)


@dataclass
class FTMSProcessResult:
    """Complete result of FTMS processing for a single file"""
    detection: DetectionResult
    metadata: dict
    thumbnail: Optional[ThumbnailResult]
    checksum: str
    file_size: int

    def to_dict(self) -> dict:
        return {
            "category": self.detection.category,
            "mime_type": self.detection.mime_type,
            "extension": self.detection.extension,
            "is_previewable": self.detection.is_previewable,
            "is_streamable": self.detection.is_streamable,
            "icon": self.detection.icon,
            "color": self.detection.color,
            "metadata": self.metadata,
            "has_thumbnail": self.thumbnail is not None,
            "checksum": self.checksum,
            "file_size": self.file_size
        }


class FTMSRouter:
    """
    Main FTMS orchestrator.
    Detects → Extracts Metadata → Generates Thumbnail
    """

    @staticmethod
    async def process(
        file_data: bytes,
        filename: str
    ) -> FTMSProcessResult:
        """Process a file through the full FTMS pipeline"""

        logger.info(f"⚙️ FTMS processing: {filename} ({len(file_data)} bytes)")

        # 1. Detect file type
        detection = FTMSDetector.detect(file_data, filename)
        logger.info(
            f"📂 Detected: {detection.category} | {detection.mime_type}"
        )

        # 2. Extract metadata (parallel-ish via async)
        metadata = await MetadataExtractor.extract(
            file_data,
            detection.category,
            detection.mime_type
        )
        logger.info(f"📋 Metadata keys: {list(metadata.keys())}")

        # 3. Generate thumbnail
        thumbnail = await ThumbnailGenerator.generate(
            file_data,
            detection.category,
            detection.mime_type,
            filename
        )
        logger.info(
            f"🖼️ Thumbnail: {'generated' if thumbnail else 'not available'}"
        )

        # 4. Checksum
        checksum = hashlib.sha256(file_data).hexdigest()

        return FTMSProcessResult(
            detection=detection,
            metadata=metadata,
            thumbnail=thumbnail,
            checksum=checksum,
            file_size=len(file_data)
        )
Step 7: Folder Service
Python

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
Step 8: Search Service
Python

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
Step 9: New API Routes
Folders Route
Python

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
Media Route
Python

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
Search Route
Python

# app/api/routes/search.py

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import datetime

from app.database.connection import get_db
from app.database.models import User
from app.database.schemas import FileResponse
from app.services.search_service import SearchService
from app.api.middleware import get_current_user

router = APIRouter(prefix="/api/search", tags=["Search"])


@router.get("/")
async def search(
    q: str = Query(default="", description="Search query"),
    category: Optional[str] = Query(default=None),
    folder_id: Optional[str] = Query(default=None),
    is_favorite: Optional[bool] = Query(default=None),
    date_from: Optional[datetime] = Query(default=None),
    date_to: Optional[datetime] = Query(default=None),
    min_size_mb: Optional[float] = Query(default=None),
    max_size_mb: Optional[float] = Query(default=None),
    sort_by: str = Query(default="created_at"),
    sort_order: str = Query(default="desc"),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Full text search with all filters"""
    result = await SearchService.search_files(
        db=db,
        user_id=current_user.id,
        query=q,
        category=category,
        folder_id=folder_id,
        is_favorite=is_favorite,
        date_from=date_from,
        date_to=date_to,
        min_size=int(min_size_mb * 1024 * 1024) if min_size_mb else None,
        max_size=int(max_size_mb * 1024 * 1024) if max_size_mb else None,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        limit=limit
    )

    return {
        "files": [FileResponse.model_validate(f) for f in result["files"]],
        "total": result["total"],
        "page": page,
        "limit": limit,
        "has_more": result["has_more"],
        "query": q
    }


@router.get("/stats")
async def storage_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get storage breakdown by category"""
    return await SearchService.get_storage_stats(db, current_user.id)


@router.get("/recent")
async def recent_files(
    days: int = Query(default=7, ge=1, le=30),
    limit: int = Query(default=20, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get recently uploaded files"""
    files = await SearchService.get_recent_files(
        db, current_user.id, days, limit
    )
    return {
        "files": [FileResponse.model_validate(f) for f in files],
        "days": days
    }
Step 10: Update Files Route + Main App
Update upload in files.py (integrate FTMS)
Python

# Replace process_upload in app/api/routes/files.py

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
Update main.py
Python

# app/main.py - Add new routers

from app.api.routes.auth import router as auth_router
from app.api.routes.files import router as files_router
from app.api.routes.folders import router as folders_router
from app.api.routes.media import router as media_router
from app.api.routes.search import router as search_router

app.include_router(auth_router)
app.include_router(files_router)
app.include_router(folders_router)
app.include_router(media_router)
app.include_router(search_router)
Complete API Reference
text

AUTH
POST   /api/auth/register              Register
POST   /api/auth/login                 Login
GET    /api/auth/me                    Get profile
POST   /api/auth/telegram/connect      Send OTP
POST   /api/auth/telegram/verify       Verify OTP
DELETE /api/auth/telegram/disconnect   Disconnect

FILES
POST   /api/files/upload               Upload file
GET    /api/files/list                 List files
GET    /api/files/status/{id}          Upload status
GET    /api/files/download/{id}        Download file
PATCH  /api/files/{id}                 Update metadata
DELETE /api/files/{id}                 Delete file

FOLDERS
POST   /api/folders/                   Create folder
GET    /api/folders/tree               Get folder tree
PATCH  /api/folders/{id}/rename        Rename
PATCH  /api/folders/{id}/move          Move
DELETE /api/folders/{id}               Delete

MEDIA
GET    /api/media/photos               All photos (gallery)
GET    /api/media/videos               All videos
GET    /api/media/audio                All audio
GET    /api/media/thumbnail/{id}       Get thumbnail
GET    /api/media/favorites            Favorites

SEARCH
GET    /api/search/                    Full search
GET    /api/search/stats               Storage stats
GET    /api/search/recent              Recent files