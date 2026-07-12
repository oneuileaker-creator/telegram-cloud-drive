# app/api/routes/auth.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.database.connection import get_db
from app.database.models import User
from app.database.schemas import (
    UserRegister, UserLogin, TokenResponse,
    UserResponse, TelegramConnect,
    TelegramVerify, TelegramConnectResponse
)
from app.services.auth_service import AuthService
from app.services.telegram_service import TelegramService
from app.api.middleware import get_current_user
import logging

router = APIRouter(prefix="/api/auth", tags=["Authentication"])
logger = logging.getLogger(__name__)


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED
)
async def register(
    data: UserRegister,
    db: AsyncSession = Depends(get_db)
):
    """Register a new FTMS account"""
    try:
        user = await AuthService.create_user(db, data)
        token = AuthService.create_access_token(user.id, user.email)

        return TokenResponse(
            access_token=token,
            user=UserResponse.model_validate(user)
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/login", response_model=TokenResponse)
async def login(
    data: UserLogin,
    db: AsyncSession = Depends(get_db)
):
    """Login to FTMS"""
    user = await AuthService.authenticate_user(db, data.email, data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    token = AuthService.create_access_token(user.id, user.email)
    return TokenResponse(
        access_token=token,
        user=UserResponse.model_validate(user)
    )


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    return UserResponse.model_validate(current_user)


# ─── Telegram Auth Flow ───────────────────────────────────────

@router.post("/telegram/connect", response_model=TelegramConnectResponse)
async def telegram_connect(
    data: TelegramConnect,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Step 1: Start Telegram auth - sends OTP to phone
    """
    try:
        service = TelegramService(
            api_id=data.api_id,
            api_hash=data.api_hash
        )
        result = await service.send_code(data.phone_number)

        # Temporarily store credentials (not yet verified)
        await db.execute(
            update(User)
            .where(User.id == current_user.id)
            .values(
                telegram_api_id=str(data.api_id),
                telegram_api_hash=data.api_hash,
                telegram_phone=data.phone_number,
                telegram_session=result["session_string"]
            )
        )
        await db.commit()

        return TelegramConnectResponse(
            status="code_sent",
            message=f"Verification code sent to {data.phone_number}",
            phone_code_hash=result["phone_code_hash"]
        )
    except Exception as e:
        logger.error(f"Telegram connect error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        await service.disconnect()


@router.post("/telegram/verify", response_model=TelegramConnectResponse)
async def telegram_verify(
    data: TelegramVerify,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Step 2: Verify OTP and complete Telegram connection
    """
    if not current_user.telegram_api_id:
        raise HTTPException(
            status_code=400,
            detail="Start connection first via /telegram/connect"
        )

    try:
        service = TelegramService(
            api_id=int(current_user.telegram_api_id),
            api_hash=current_user.telegram_api_hash,
            session_string=current_user.telegram_session or ""
        )

        result = await service.verify_code(
            phone_number=data.phone_number,
            code=data.code,
            phone_code_hash=data.phone_code_hash
        )

        if result["status"] == "2fa_required":
            return TelegramConnectResponse(
                status="2fa_required",
                message="2FA password required",
                requires_2fa=True
            )

        # Create storage channel
        service2 = TelegramService(
            api_id=int(current_user.telegram_api_id),
            api_hash=current_user.telegram_api_hash,
            session_string=result["session_string"]
        )
        channel_id = await service2.setup_storage_channel()

        # Save everything to DB
        await db.execute(
            update(User)
            .where(User.id == current_user.id)
            .values(
                telegram_session=result["session_string"],
                telegram_channel_id=channel_id,
                is_telegram_connected=True
            )
        )
        await db.commit()

        logger.info(f"✅ User {current_user.email} connected Telegram")
        return TelegramConnectResponse(
            status="connected",
            message="Telegram connected successfully! Storage ready."
        )
    except Exception as e:
        logger.error(f"Telegram verify error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        await service.disconnect()


@router.delete("/telegram/disconnect")
async def telegram_disconnect(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Disconnect Telegram from FTMS account"""
    await db.execute(
        update(User)
        .where(User.id == current_user.id)
        .values(
            telegram_session=None,
            telegram_api_id=None,
            telegram_api_hash=None,
            telegram_channel_id=None,
            is_telegram_connected=False
        )
    )
    await db.commit()
    return {"message": "Telegram disconnected"}
