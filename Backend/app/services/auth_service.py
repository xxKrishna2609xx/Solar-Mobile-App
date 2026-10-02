from datetime import datetime, timedelta, timezone
from typing import Optional
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.core.exceptions import BadRequestException, NotFoundException, UnauthorizedException
from app.core.security import (
    create_access_token,
    generate_otp,
    generate_random_token,
    hash_token,
    verify_token_hash,
)
from app.models.auth import OtpCode, RefreshToken
from app.models.user import User
from app.schemas.auth import TokenResponse
from app.services.sms import get_sms_provider


class AuthService:
    """Service handling OTP authentication, tokens, and session lifecycles."""

    @staticmethod
    async def request_otp(db: AsyncSession, phone: str) -> None:
        """Rate-limited OTP dispatch for active registered users."""
        now = datetime.now(timezone.utc)
        ten_minutes_ago = now - timedelta(minutes=10)

        # 1. Rate Limit check: max 3 OTP requests in last 10 minutes
        count_stmt = select(func.count(OtpCode.id)).where(
            OtpCode.phone == phone,
            OtpCode.created_at >= ten_minutes_ago,
        )
        recent_requests_count = (await db.execute(count_stmt)).scalar() or 0
        if recent_requests_count >= 3:
            raise BadRequestException("Too many OTP requests. Please wait a few minutes before trying again.")

        # 2. Check if user exists and is active
        user_stmt = select(User).where(
            User.phone == phone,
            User.is_deleted == False,  # noqa: E712
            User.is_active == True,   # noqa: E712
        )
        user = (await db.execute(user_stmt)).scalar_one_or_none()

        # If user does not exist or is inactive, return silently to prevent user enumeration
        if not user:
            return

        # 3. Generate OTP, hash, and store
        otp_code = generate_otp(length=settings.OTP_LENGTH)
        code_hash = hash_token(otp_code)
        expires_at = now + timedelta(seconds=settings.OTP_EXPIRE_SECONDS)

        otp_record = OtpCode(
            phone=phone,
            code_hash=code_hash,
            expires_at=expires_at,
            attempts=0,
        )
        db.add(otp_record)
        await db.commit()

        # 4. Dispatch SMS
        sms_provider = get_sms_provider()
        await sms_provider.send_otp(phone=phone, otp_code=otp_code)

    @staticmethod
    async def verify_otp(
        db: AsyncSession,
        phone: str,
        otp: str,
        device_info: Optional[str] = None,
    ) -> TokenResponse:
        """Verify OTP, record session, and generate tokens."""
        now = datetime.now(timezone.utc)

        # 1. Fetch latest active OTP record for phone
        stmt = (
            select(OtpCode)
            .where(
                OtpCode.phone == phone,
                OtpCode.consumed_at.is_(None),
                OtpCode.expires_at > now,
            )
            .order_by(OtpCode.created_at.desc())
            .limit(1)
        )
        otp_record = (await db.execute(stmt)).scalar_one_or_none()

        if not otp_record:
            raise BadRequestException("Invalid or expired OTP.")

        if otp_record.attempts >= 5:
            raise BadRequestException("Maximum OTP attempts exceeded. Please request a new OTP.")

        # 2. Verify hash
        otp_record.attempts += 1
        if not verify_token_hash(otp, otp_record.code_hash):
            await db.commit()
            raise BadRequestException("Invalid OTP code.")

        # 3. Mark consumed
        otp_record.consumed_at = now

        # 4. Fetch user
        user_stmt = select(User).where(
            User.phone == phone,
            User.is_deleted == False,  # noqa: E712
            User.is_active == True,   # noqa: E712
        )
        user = (await db.execute(user_stmt)).scalar_one_or_none()
        if not user:
            raise NotFoundException("Active user not found.")

        # 5. Update user login time
        user.last_login_at = now

        # 6. Issue Access Token and Refresh Token
        access_token = create_access_token(subject=str(user.id), role=user.role.value)
        plain_refresh_token = generate_random_token()
        refresh_hash = hash_token(plain_refresh_token)
        refresh_expires = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

        refresh_record = RefreshToken(
            user_id=user.id,
            token_hash=refresh_hash,
            expires_at=refresh_expires,
            device_info=device_info,
        )
        db.add(refresh_record)
        await db.commit()
        await db.refresh(user)

        return TokenResponse(
            access_token=access_token,
            refresh_token=plain_refresh_token,
            user=user,
        )

    @staticmethod
    async def refresh_token(
        db: AsyncSession,
        refresh_token_plain: str,
    ) -> TokenResponse:
        """Rotate refresh token and issue new access token."""
        now = datetime.now(timezone.utc)
        token_hash = hash_token(refresh_token_plain)

        stmt = select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at > now,
        )
        token_record = (await db.execute(stmt)).scalar_one_or_none()

        if not token_record:
            raise UnauthorizedException("Invalid, expired, or revoked refresh token.")

        # Fetch associated user
        user_stmt = select(User).where(
            User.id == token_record.user_id,
            User.is_deleted == False,  # noqa: E712
            User.is_active == True,   # noqa: E712
        )
        user = (await db.execute(user_stmt)).scalar_one_or_none()
        if not user:
            raise UnauthorizedException("User account is inactive or deleted.")

        # Revoke old token (Rotation)
        token_record.revoked_at = now

        # Issue new pair
        access_token = create_access_token(subject=str(user.id), role=user.role.value)
        new_refresh_plain = generate_random_token()
        new_refresh_hash = hash_token(new_refresh_plain)
        new_expires = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

        new_record = RefreshToken(
            user_id=user.id,
            token_hash=new_refresh_hash,
            expires_at=new_expires,
            device_info=token_record.device_info,
        )
        db.add(new_record)
        await db.commit()
        await db.refresh(user)

        return TokenResponse(
            access_token=access_token,
            refresh_token=new_refresh_plain,
            user=user,
        )

    @staticmethod
    async def logout(db: AsyncSession, refresh_token_plain: str) -> None:
        """Revoke refresh token on logout."""
        token_hash = hash_token(refresh_token_plain)
        stmt = select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked_at.is_(None),
        )
        token_record = (await db.execute(stmt)).scalar_one_or_none()
        if token_record:
            token_record.revoked_at = datetime.now(timezone.utc)
            await db.commit()

    @staticmethod
    async def update_fcm_token(db: AsyncSession, user: User, fcm_token: str) -> User:
        """Update user device FCM token for push notifications."""
        user.fcm_token = fcm_token
        await db.commit()
        await db.refresh(user)
        return user
