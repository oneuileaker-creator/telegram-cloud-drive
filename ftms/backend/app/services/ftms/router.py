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
