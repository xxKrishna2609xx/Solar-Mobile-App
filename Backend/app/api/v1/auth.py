from typing import Optional
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    EmailVerificationResponse,
    FcmTokenUpdate,
    LogoutRequest,
    OtpRequest,
    OtpRequestResponse,
    OtpVerify,
    PasswordLoginRequest,
    RefreshTokenRequest,
    SendEmailVerificationRequest,
    TokenResponse,
    UserMeResponse,
    UserRegisterRequest,
    VerifyEmailRequest,
)

from app.schemas.user import UserRead
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/login",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Authenticate with Phone/Email and Password (salted bcrypt & injection protected)",
)
async def login_with_password(
    payload: PasswordLoginRequest,
    db: Optional[AsyncSession] = Depends(get_db),
):
    return await AuthService.login_with_password(
        identifier=payload.identifier,
        password=payload.password,
        device_info=payload.device_info,
        db=db,
    )


@router.post(
    "/register",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user account with salted bcrypt password in DB",
)
async def register_user(
    payload: UserRegisterRequest,
):
    return await AuthService.register_user(
        name=payload.name,
        phone=payload.phone,
        password=payload.password,
        role=payload.role,
        email=payload.email,
    )


@router.post(
    "/send-verification-email",
    response_model=EmailVerificationResponse,
    status_code=status.HTTP_200_OK,
    summary="Dispatch a 6-digit email verification code to user email",
)
async def send_verification_email(
    payload: SendEmailVerificationRequest,
):
    await AuthService.send_email_verification(email=payload.email)
    return EmailVerificationResponse(email=payload.email)


@router.post(
    "/verify-email",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Verify email with 6-digit code and activate client account",
)
async def verify_email(
    payload: VerifyEmailRequest,
):
    return await AuthService.verify_email(
        email=payload.email,
        code=payload.code,
    )



@router.post(
    "/request-otp",
    response_model=OtpRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Request a 6-digit OTP for login",
)
async def request_otp(
    payload: OtpRequest,
    db: Optional[AsyncSession] = Depends(get_db),
):
    await AuthService.request_otp(phone=payload.phone, db=db)
    return OtpRequestResponse()


@router.post(
    "/verify-otp",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and receive JWT access + refresh tokens",
)
async def verify_otp(
    payload: OtpVerify,
    db: Optional[AsyncSession] = Depends(get_db),
):
    return await AuthService.verify_otp(
        phone=payload.phone,
        otp=payload.otp,
        device_info=payload.device_info,
        db=db,
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Rotate refresh token and get a new access token",
)
async def refresh_token(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.refresh_token(
        db=db,
        refresh_token_plain=payload.refresh_token,
    )


@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="Revoke the refresh token on logout",
)
async def logout(
    payload: LogoutRequest,
    db: Optional[AsyncSession] = Depends(get_db),
):
    if db is not None:
        await AuthService.logout(db=db, refresh_token_plain=payload.refresh_token)
    return {"message": "Logged out successfully."}


@router.get(
    "/me",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Get current authenticated user profile",
)
async def get_me(
    current_user=Depends(get_current_user),
):
    return {
        "id": str(current_user.id),
        "name": getattr(current_user, "name", ""),
        "phone": getattr(current_user, "phone", ""),
        "email": getattr(current_user, "email", None),
        "role": getattr(current_user.role, "value", str(current_user.role)),
        "is_active": getattr(current_user, "is_active", True),
    }


@router.put(
    "/me/fcm-token",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Update device FCM token for push notifications",
)
async def update_fcm_token(
    payload: FcmTokenUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.update_fcm_token(
        db=db,
        user=current_user,
        fcm_token=payload.fcm_token,
    )
