import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator
from app.core.security import normalize_phone
from app.models.enums import UserRole
from app.schemas.team import TeamRead


class UserBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., description="10-digit Indian phone number")
    role: UserRole = Field(..., description="Role of the user")
    team_id: Optional[uuid.UUID] = Field(None, description="Required if role is labour")

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return normalize_phone(v)


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone: Optional[str] = None
    role: Optional[UserRole] = None
    team_id: Optional[uuid.UUID] = None
    is_active: Optional[bool] = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            return normalize_phone(v)
        return v


class UserRead(BaseModel):
    id: uuid.UUID
    name: str
    phone: str
    role: UserRole
    team_id: Optional[uuid.UUID]
    team: Optional[TeamRead] = None
    is_active: bool
    fcm_token: Optional[str] = None
    last_login_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
