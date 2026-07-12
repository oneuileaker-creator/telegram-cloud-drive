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
            except Exception as e:
                logger.warning(f"Failed to generate PDF thumbnail: {e}")
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
                    try:
                        font = ImageFont.truetype("arial.ttf", 12)
                        title_font = ImageFont.truetype("arialbd.ttf", 14)
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
