from typing import Optional
from pydantic import BaseModel, Field, field_validator
from app.core.security import normalize_phone
from app.schemas.user import UserRead


class PasswordLoginRequest(BaseModel):
    identifier: str = Field(..., min_length=3, max_length=100, description="Phone number or Email address")
    password: str = Field(..., min_length=4, max_length=128, description="User password")
    device_info: Optional[str] = Field(None, description="Optional device details/user-agent")


class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Full name")
    phone: str = Field(..., description="10-digit Indian phone number")
    email: Optional[str] = Field(None, max_length=100, description="Email address")
    password: str = Field(..., min_length=6, max_length=128, description="Password (min 6 chars)")
    role: str = Field("client", description="Role: admin, client, sales, installer")

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return normalize_phone(v)


class OtpRequest(BaseModel):
    phone: str = Field(..., description="10-digit Indian mobile number")

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return normalize_phone(v)


class OtpRequestResponse(BaseModel):
    message: str = "If the mobile number is registered, an OTP has been dispatched."
    email: Optional[str] = None


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


class SendEmailVerificationRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=120, description="Email address to send verification code")


class VerifyEmailRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=120, description="Email address being verified")
    code: str = Field(..., min_length=4, max_length=10, description="6-digit verification code received")


class EmailVerificationResponse(BaseModel):
    message: str = "Email verification code dispatched successfully."
    email: str

