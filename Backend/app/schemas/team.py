import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field
from app.models.enums import TeamType


class TeamBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Name of the team (e.g., Structure Team A)")
    type: TeamType = Field(..., description="Team type (structure, electrical, civil)")


class TeamCreate(TeamBase):
    pass


class TeamUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    type: Optional[TeamType] = None


class TeamRead(TeamBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
