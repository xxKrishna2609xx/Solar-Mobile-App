from typing import Optional
from pydantic import BaseModel, Field, field_validator
from app.core.security import normalize_phone
from app.schemas.user import UserRead


class OtpRequest(BaseModel):
    phone: str = Field(..., description="10-digit Indian mobile number")

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return normalize_phone(v)


class OtpRequestResponse(BaseModel):
    message: str = "If the mobile number is registered, an OTP has been dispatched."


class OtpVerify(BaseModel):
    phone: str = Field(..., description="10-digit Indian mobile number")
    otp: str = Field(..., min_length=4, max_length=10, description="OTP code received")
    device_info: Optional[str] = Field(None, description="Optional device details/user-agent")

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return normalize_phone(v)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserRead


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., description="Active refresh token")


class LogoutRequest(BaseModel):
    refresh_token: str = Field(..., description="Refresh token to revoke")


class FcmTokenUpdate(BaseModel):
    fcm_token: str = Field(..., min_length=10, max_length=255, description="FCM device token")


class UserMeResponse(BaseModel):
    user: UserRead
