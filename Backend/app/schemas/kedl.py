from datetime import date, datetime
from typing import Dict, List, Optional
import uuid
from pydantic import BaseModel, Field
from app.models.enums import KedlDemandStatus, KedlFileStatus, KedlFileType
from app.schemas.user import UserRead


class KedlFileInitRequest(BaseModel):
    assigned_to: Optional[uuid.UUID] = Field(None, description="Optional KEDL employee user ID to assign all 3 files to")


class KedlFileUpdate(BaseModel):
    application_no: Optional[str] = Field(None, max_length=100)
    remarks: Optional[str] = None
    assigned_to: Optional[uuid.UUID] = None


class KedlFileStatusUpdate(BaseModel):
    status: KedlFileStatus = Field(..., description="Target status (submitted, demand_raised, demand_paid, approved, rejected)")
    note: Optional[str] = Field(None, description="Optional status change note")


class KedlDemandCreate(BaseModel):
    description: str = Field(..., min_length=3, description="Demand description / requirement details")
    amount: Optional[int] = Field(None, ge=0, description="Amount in paise if a fee is requested")
    due_date: Optional[date] = Field(None, description="Payment/submission due date (YYYY-MM-DD)")


class KedlDemandUpdate(BaseModel):
    status: KedlDemandStatus = Field(..., description="paid or waived")
    paid_on: Optional[datetime] = Field(default_factory=datetime.utcnow)


class KedlDemandRead(BaseModel):
    id: uuid.UUID
    kedl_file_id: uuid.UUID
    description: str
    amount: Optional[int] = None
    due_date: Optional[date] = None
    status: KedlDemandStatus
    paid_on: Optional[datetime] = None
    receipt_key: Optional[str] = None
    receipt_url: Optional[str] = None
    raised_on: datetime
    raised_by: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime
    raiser: Optional[UserRead] = None

    class Config:
        from_attributes = True


class KedlDocumentRead(BaseModel):
    id: uuid.UUID
    kedl_file_id: uuid.UUID
    doc_type: str
    file_key: str
    original_name: str
    download_url: Optional[str] = None
    uploaded_by: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime
    uploader: Optional[UserRead] = None

    class Config:
        from_attributes = True


class KedlStatusLogRead(BaseModel):
    id: uuid.UUID
    kedl_file_id: uuid.UUID
    from_status: Optional[KedlFileStatus] = None
    to_status: KedlFileStatus
    changed_by: Optional[uuid.UUID] = None
    note: Optional[str] = None
    created_at: datetime
    actor: Optional[UserRead] = None

    class Config:
        from_attributes = True


class KedlFileRead(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    file_type: KedlFileType
    status: KedlFileStatus
    application_no: Optional[str] = None
    submitted_on: Optional[datetime] = None
    approved_on: Optional[datetime] = None
    assigned_to: Optional[uuid.UUID] = None
    remarks: Optional[str] = None
    is_deleted: bool
    created_at: datetime
    updated_at: datetime
    assignee: Optional[UserRead] = None
    demands: Optional[List[KedlDemandRead]] = None
    documents: Optional[List[KedlDocumentRead]] = None
    status_logs: Optional[List[KedlStatusLogRead]] = None

    class Config:
        from_attributes = True


class KedlDashboardMetrics(BaseModel):
    total_files: int
    by_file_type: Dict[str, int]
    by_status: Dict[str, int]
    open_demands_count: int
    overdue_demands_count: int
