# app/services/auth_service.py

from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.config import settings
from app.database.models import User
from app.database.schemas import UserRegister
import logging

logger = logging.getLogger(__name__)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:

    # ─── Password Utils ───────────────────────────────────────

    @staticmethod
    def hash_password(password: str) -> str:
        return pwd_context.hash(password)

    @staticmethod
    def verify_password(plain: str, hashed: str) -> bool:
        return pwd_context.verify(plain, hashed)

    # ─── JWT Utils ────────────────────────────────────────────

    @staticmethod
    def create_access_token(
        user_id: str,
        email: str,
        expires_delta: Optional[timedelta] = None
    ) -> str:
        expire = datetime.utcnow() + (
            expires_delta or
            timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        payload = {
            "sub": str(user_id),
            "email": email,
            "exp": expire,
            "iat": datetime.utcnow(),
            "type": "access"
        }
        return jwt.encode(
            payload,
            settings.SECRET_KEY, # Note: using Settings.SECRET_KEY or Settings.JWT_SECRET. The Step 6 used settings.JWT_SECRET. Let's make sure we match Step 6 exactly. Let's use Settings.JWT_SECRET.
            algorithm=settings.JWT_ALGORITHM
        )

    @staticmethod
    def decode_token(token: str) -> dict:
        try:
            payload = jwt.decode(
                token,
                settings.JWT_SECRET,
                algorithms=[settings.JWT_ALGORITHM]
            )
            return payload
        except JWTError as e:
            logger.warning(f"JWT decode error: {e}")
            raise

    # ─── User Operations ──────────────────────────────────────

    @staticmethod
    async def create_user(
        db: AsyncSession,
        data: UserRegister
    ) -> User:
        # Check if email exists
        result = await db.execute(
            select(User).where(User.email == data.email)
        )
        if result.scalar_one_or_none():
            raise ValueError("Email already registered")

        # Check if username exists
        result = await db.execute(
            select(User).where(User.username == data.username)
        )
        if result.scalar_one_or_none():
            raise ValueError("Username already taken")

        user = User(
            email=data.email,
            username=data.username,
            password_hash=AuthService.hash_password(data.password)
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        logger.info(f"✅ New user created: {user.email}")
        return user

    @staticmethod
    async def authenticate_user(
        db: AsyncSession,
        email: str,
        password: str
    ) -> Optional[User]:
        result = await db.execute(
            select(User).where(User.email == email)
        )
        user = result.scalar_one_or_none()

        if not user:
            return None
        if not AuthService.verify_password(password, user.password_hash):
            return None

        # Update last login
        user.last_login = datetime.utcnow()
        await db.commit()

        return user

    @staticmethod
    async def get_user_by_id(
        db: AsyncSession,
        user_id: UUID
    ) -> Optional[User]:
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
