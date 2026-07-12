# app/services/telegram_service.py

from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.errors import (
    SessionPasswordNeededError,
    PhoneCodeInvalidError,
    PhoneCodeExpiredError,
    ApiIdInvalidError,
    FloodWaitError
)
from telethon.tl.functions.channels import CreateChannelRequest
from telethon.tl.functions.messages import ExportChatInviteRequest
from telethon.tl.types import PeerChannel

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.database.models import User
from app.config import settings
import logging
import asyncio
from typing import Dict

logger = logging.getLogger(__name__)

FTMS_CHANNEL_NAME = "FTMS-Storage"

# ─── Global Connection Pool ────────────────────────────────────────────────────
# Keyed by session_string → TelegramClient.
# Clients stay connected across requests, eliminating per-request TCP overhead.
_pool: Dict[str, TelegramClient] = {}
_pool_lock = asyncio.Lock()


async def _get_pooled_client(session_string: str, api_id: int, api_hash: str) -> TelegramClient:
    """Return a connected (and pooled) TelegramClient for the given session."""
    async with _pool_lock:
        client = _pool.get(session_string)
        if client is None:
            client = TelegramClient(
                StringSession(session_string),
                api_id,
                api_hash,
                connection_retries=3,
                retry_delay=1
            )
            await client.connect()
            _pool[session_string] = client
            logger.info("🔗 New pooled Telegram connection created")
        elif not client.is_connected():
            await client.connect()
            logger.info("🔗 Reconnected pooled Telegram client")
        return client


class TelegramService:

    def __init__(
        self,
        api_id: int,
        api_hash: str,
        session_string: str = "",
        _pooled_client: TelegramClient = None
    ):
        self.api_id = api_id
        self.api_hash = api_hash
        self.session_string = session_string
        self._is_pooled = _pooled_client is not None
        self.client = _pooled_client or TelegramClient(
            StringSession(session_string),
            api_id,
            api_hash
        )

    @classmethod
    async def get_pooled(cls, api_id: int, api_hash: str, session_string: str) -> "TelegramService":
        """Get a TelegramService backed by a persistent pooled connection."""
        client = await _get_pooled_client(session_string, api_id, api_hash)
        return cls(api_id, api_hash, session_string, _pooled_client=client)

    # ─── Auth Flow ────────────────────────────────────────────

    async def send_code(self, phone_number: str) -> dict:
        """Step 1: Send OTP to phone"""
        try:
            await self.client.connect()
            result = await self.client.send_code_request(phone_number)

            session_string = self.client.session.save()
            logger.info(f"✅ Code sent to {phone_number}")
            return {
                "phone_code_hash": result.phone_code_hash,
                "status": "code_sent",
                "session_string": session_string
            }
        except ApiIdInvalidError:
            raise ValueError("Invalid API ID or API Hash")
        except FloodWaitError as e:
            raise ValueError(f"Too many attempts. Wait {e.seconds} seconds")
        except Exception as e:
            logger.error(f"Send code error: {e}")
            raise

    async def verify_code(
        self,
        phone_number: str,
        code: str,
        phone_code_hash: str
    ) -> dict:
        """Step 2: Verify OTP and get session"""
        try:
            await self.client.connect()
            await self.client.sign_in(
                phone=phone_number,
                code=code,
                phone_code_hash=phone_code_hash
            )

            # Get session string to store in DB
            session_string = self.client.session.save()

            logger.info("✅ Telegram auth successful")
            return {
                "session_string": session_string,
                "status": "authenticated"
            }
        except SessionPasswordNeededError:
            return {
                "status": "2fa_required",
                "session_string": None
            }
        except PhoneCodeInvalidError:
            raise ValueError("Invalid verification code")
        except PhoneCodeExpiredError:
            raise ValueError("Code expired. Request a new one")

    async def verify_2fa(
        self,
        password: str
    ) -> dict:
        """Step 2b: Handle 2FA if enabled"""
        try:
            await self.client.connect()
            await self.client.sign_in(password=password)
            session_string = self.client.session.save()
            return {
                "session_string": session_string,
                "status": "authenticated"
            }
        except Exception as e:
            raise ValueError(f"2FA failed: {e}")

    async def disconnect(self):
        # Pooled clients stay alive for reuse; only disconnect non-pooled ones
        if not self._is_pooled and self.client.is_connected():
            await self.client.disconnect()

    # ─── Channel Setup ────────────────────────────────────────

    async def setup_storage_channel(self) -> int:
        """Create a private channel to use as storage"""
        try:
            if not self.client.is_connected():
                await self.client.connect()
            result = await self.client(CreateChannelRequest(
                title=FTMS_CHANNEL_NAME,
                about="FTMS Cloud Storage - Do not delete",
                megagroup=False,  # Regular channel not supergroup
            ))
            channel = result.chats[0]
            channel_id = channel.id

            logger.info(f"✅ Storage channel created: {channel_id}")
            return channel_id

        except Exception as e:
            logger.error(f"Channel creation error: {e}")
            raise

    async def get_or_create_channel(self, channel_id: int = None) -> int:
        """Get existing channel or create new one"""
        if not self.client.is_connected():
            await self.client.connect()

        if channel_id:
            try:
                # Verify channel still exists
                await self.client.get_entity(PeerChannel(channel_id))
                return channel_id
            except Exception:
                try:
                    logger.info("Channel entity not cached, fetching dialogs...")
                    await self.client.get_dialogs()
                    await self.client.get_entity(PeerChannel(channel_id))
                    return channel_id
                except Exception:
                    logger.warning("Channel not found, creating new one")

        return await self.setup_storage_channel()

    # ─── File Operations ──────────────────────────────────────

    async def upload_file(
        self,
        file_data: bytes,
        file_name: str,
        channel_id: int,
        caption: str = "",
        progress_callback=None
    ) -> int:
        """Upload a file to Telegram channel"""
        try:
            if not self.client.is_connected():
                await self.client.connect()

            # Upload file bytes
            uploaded = await self.client.upload_file(
                file_data,
                file_name=file_name,
                progress_callback=progress_callback
            )

            try:
                message = await self.client.send_file(
                    entity=PeerChannel(channel_id),
                    file=uploaded,
                    caption=caption,
                    silent=True,
                    force_document=True     # Always as document not media
                )
            except Exception:
                logger.info("Channel entity not cached, fetching dialogs...")
                await self.client.get_dialogs()
                message = await self.client.send_file(
                    entity=PeerChannel(channel_id),
                    file=uploaded,
                    caption=caption,
                    silent=True,
                    force_document=True
                )

            logger.info(f"✅ Uploaded {file_name} → msg_id: {message.id}")
            return message.id

        except FloodWaitError as e:
            logger.warning(f"Flood wait: {e.seconds}s")
            await asyncio.sleep(e.seconds)
            return await self.upload_file(
                file_data, file_name, channel_id, caption
            )
        except Exception as e:
            logger.error(f"Upload error: {e}")
            raise

    async def download_file(
        self,
        message_id: int,
        channel_id: int,
        progress_callback=None
    ) -> bytes:
        """Download a file by message ID"""
        try:
            if not self.client.is_connected():
                await self.client.connect()

            try:
                message = await self.client.get_messages(
                    PeerChannel(channel_id),
                    ids=message_id
                )
            except Exception:
                logger.info("Channel entity not cached, fetching dialogs...")
                await self.client.get_dialogs()
                message = await self.client.get_messages(
                    PeerChannel(channel_id),
                    ids=message_id
                )

            if not message:
                raise ValueError(f"Message {message_id} not found")

            file_data = await self.client.download_media(
                message,
                file=bytes,
                progress_callback=progress_callback
            )

            return file_data

        except Exception as e:
            logger.error(f"Download error: {e}")
            raise

    async def download_file_stream(
        self,
        message_id: int,
        channel_id: int,
        offset: int = 0,
        limit: int = None,
        chunk_size: int = 2 * 1024 * 1024  # 2MB for fewer round-trips
    ):
        """Yield blocks of file data as they are downloaded from Telegram"""
        try:
            if not self.client.is_connected():
                await self.client.connect()

            try:
                message = await self.client.get_messages(
                    PeerChannel(channel_id),
                    ids=message_id
                )
            except Exception:
                logger.info("Channel entity not cached, fetching dialogs...")
                await self.client.get_dialogs()
                message = await self.client.get_messages(
                    PeerChannel(channel_id),
                    ids=message_id
                )

            if not message:
                raise ValueError(f"Message {message_id} not found")

            async for chunk in self.client.iter_download(
                message.media,
                offset=offset,
                limit=limit,
                request_size=chunk_size
            ):
                yield bytes(chunk)

        except Exception as e:
            logger.error(f"Download stream error: {e}")
            raise

    async def delete_messages(
        self,
        message_ids: list[int],
        channel_id: int
    ) -> bool:
        """Delete file messages from Telegram"""
        try:
            if not self.client.is_connected():
                await self.client.connect()
            try:
                await self.client.delete_messages(PeerChannel(channel_id), message_ids)
            except Exception:
                logger.info("Channel entity not cached, fetching dialogs...")
                await self.client.get_dialogs()
                await self.client.delete_messages(PeerChannel(channel_id), message_ids)
            logger.info(f"✅ Deleted messages: {message_ids}")
            return True
        except Exception as e:
            logger.error(f"Delete error: {e}")
            return False

    async def upload_thumbnail(
        self,
        thumbnail_data: bytes,
        channel_id: int,
        file_name: str
    ) -> int:
        """Upload thumbnail image"""
        return await self.upload_file(
            thumbnail_data,
            f"thumb_{file_name}.jpg",
            channel_id,
            caption="__thumbnail__"
        )

    # ─── Helper Factory ───────────────────────────────────────

    @classmethod
    async def from_user(cls, user: User) -> "TelegramService":
        """Create TelegramService from a User model — uses pooled connection."""
        if not user.is_telegram_connected:
            raise ValueError("Telegram not connected for this user")

        return await cls.get_pooled(
            api_id=int(user.telegram_api_id),
            api_hash=user.telegram_api_hash,
            session_string=user.telegram_session
        )
