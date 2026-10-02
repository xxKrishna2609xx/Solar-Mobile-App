from datetime import date, datetime
from typing import Any, Dict, List, Optional
import uuid
from pydantic import BaseModel, Field
from app.models.enums import WorkStatus, WorkType
from app.schemas.team import TeamRead
from app.schemas.user import UserRead


class CustomerShortForLabour(BaseModel):
    id: uuid.UUID
    name: str
    mobile: str
    address: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        from_attributes = True


class WorkPhotoRead(BaseModel):
    id: uuid.UUID
    work_assignment_id: uuid.UUID
    file_key: str
    caption: Optional[str] = None
    uploaded_by: Optional[uuid.UUID] = None
    download_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class WorkStatusLogRead(BaseModel):
    id: uuid.UUID
    work_assignment_id: uuid.UUID
    from_status: Optional[WorkStatus] = None
    to_status: WorkStatus
    changed_by: Optional[uuid.UUID] = None
    note: Optional[str] = None
    created_at: datetime
    actor: Optional[UserRead] = None

    class Config:
        from_attributes = True


class WorkAssignmentCreate(BaseModel):
    work_type: WorkType = Field(..., description="structure, electrical, or civil")
    team_id: uuid.UUID = Field(..., description="ID of the team matching work_type")
    scheduled_start: date = Field(..., description="Planned start date (YYYY-MM-DD)")
    scheduled_end: date = Field(..., description="Planned end date (YYYY-MM-DD)")
    notes: Optional[str] = Field(None, description="Instructions or assignment notes")
    override: bool = Field(False, description="Admin override if customer is not yet in ADVANCE_VERIFIED stage")
    allow_overlap: bool = Field(False, description="Allow assigning even if team has another overlapping active assignment")


class WorkAssignmentUpdate(BaseModel):
    team_id: Optional[uuid.UUID] = None
    scheduled_start: Optional[date] = None
    scheduled_end: Optional[date] = None
    notes: Optional[str] = None
    status: Optional[WorkStatus] = None


class WorkAssignmentRead(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    work_type: WorkType
    team_id: uuid.UUID
    scheduled_start: date
    scheduled_end: date
    actual_start: Optional[datetime] = None
    actual_end: Optional[datetime] = None
    status: WorkStatus
    notes: Optional[str] = None
    assigned_by: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime
    customer: Optional[CustomerShortForLabour] = None
    team: Optional[TeamRead] = None
    photos: Optional[List[WorkPhotoRead]] = None
    status_logs: Optional[List[WorkStatusLogRead]] = None

    class Config:
        from_attributes = True


class CalendarScheduleItem(BaseModel):
    assignment_id: uuid.UUID
    customer_id: uuid.UUID
    customer_name: str
    customer_address: str
    work_type: WorkType
    team_id: uuid.UUID
    team_name: str
    scheduled_start: date
    scheduled_end: date
    status: WorkStatus


class CalendarScheduleResponse(BaseModel):
    from_date: date
    to_date: date
    total_assignments: int
    by_date: Dict[str, List[CalendarScheduleItem]] = Field(
        default_factory=dict,
        description="Map of date string (YYYY-MM-DD) to list of scheduled assignments",
    )
    by_team: Dict[str, List[CalendarScheduleItem]] = Field(
        default_factory=dict,
        description="Map of team name to list of scheduled assignments",
    )
