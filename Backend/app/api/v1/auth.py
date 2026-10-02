from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.auth import (
    FcmTokenUpdate,
    LogoutRequest,
    OtpRequest,
    OtpRequestResponse,
    OtpVerify,
    RefreshTokenRequest,
    TokenResponse,
    UserMeResponse,
)
from app.schemas.user import UserRead
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post(
    "/request-otp",
    response_model=OtpRequestResponse,
    status_code=status.HTTP_200_OK,
    summary="Request a 6-digit OTP for login",
)
async def request_otp(
    payload: OtpRequest,
    db: AsyncSession = Depends(get_db),
):
    await AuthService.request_otp(db=db, phone=payload.phone)
    return OtpRequestResponse()


@router.post(
    "/verify-otp",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Verify OTP and receive JWT access + refresh tokens",
)
async def verify_otp(
    payload: OtpVerify,
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.verify_otp(
        db=db,
        phone=payload.phone,
        otp=payload.otp,
        device_info=payload.device_info,
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
    db: AsyncSession = Depends(get_db),
):
    await AuthService.logout(db=db, refresh_token_plain=payload.refresh_token)
    return {"message": "Logged out successfully."}


@router.get(
    "/me",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Get current authenticated user profile",
)
async def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


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
