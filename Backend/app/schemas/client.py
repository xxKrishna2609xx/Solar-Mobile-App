from datetime import datetime
from typing import Any, Dict, List, Optional
import uuid
from pydantic import BaseModel, Field
from app.models.enums import CustomerStage
from app.schemas.customer import CustomerRead
from app.schemas.payment import PaymentSummary


class TimelineStageItem(BaseModel):
    stage: CustomerStage
    title: str
    status: str = Field(..., description="'done', 'current', or 'upcoming'")
    date: Optional[datetime] = None
    note: Optional[str] = None


class ResponsibleContact(BaseModel):
    name: str
    phone: str
    role_title: str


class ClientHomeResponse(BaseModel):
    customer: CustomerRead
    stage: CustomerStage
    timeline: List[TimelineStageItem]
    responsible_contact: ResponsibleContact
    sales_contact: ResponsibleContact
    payment_summary: Dict[str, Any]
    system_specs: Dict[str, Any]
