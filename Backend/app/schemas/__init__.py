"""Pydantic schemas package."""
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
from app.schemas.common import (
    ErrorDetail,
    ErrorResponse,
    HealthResponse,
    PaginatedResponse,
    PaginationParams,
)
from app.schemas.team import TeamCreate, TeamRead, TeamUpdate
from app.schemas.user import UserCreate, UserRead, UserUpdate

__all__ = [
    "ErrorDetail",
    "ErrorResponse",
    "HealthResponse",
    "PaginationParams",
    "PaginatedResponse",
    "OtpRequest",
    "OtpRequestResponse",
    "OtpVerify",
    "TokenResponse",
    "RefreshTokenRequest",
    "LogoutRequest",
    "FcmTokenUpdate",
    "UserMeResponse",
    "TeamCreate",
    "TeamUpdate",
    "TeamRead",
    "UserCreate",
    "UserUpdate",
    "UserRead",
]
