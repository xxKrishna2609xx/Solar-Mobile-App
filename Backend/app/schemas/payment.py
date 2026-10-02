import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from app.models.enums import PaymentAction, PaymentMode, PaymentStatus, UserRole
from app.schemas.user import UserRead


class PaymentAuditLogRead(BaseModel):
    id: uuid.UUID
    payment_id: uuid.UUID
    action: PaymentAction
    actor_id: Optional[uuid.UUID] = None
    old_status: Optional[PaymentStatus] = None
    new_status: PaymentStatus
    note: Optional[str] = None
    created_at: datetime
    actor: Optional[UserRead] = None

    class Config:
        from_attributes = True


class PaymentCreate(BaseModel):
    amount: int = Field(..., gt=0, description="Payment amount in paise (e.g. 5000000 for Rs. 50,000)")
    mode: PaymentMode = Field(..., description="Payment mode (cash, upi, bank_transfer, cheque, other)")
    reference_no: Optional[str] = Field(None, max_length=100, description="Transaction reference / cheque number")
    paid_on: datetime = Field(default_factory=datetime.utcnow, description="Timestamp when payment was made")
    remarks: Optional[str] = Field(None, description="Optional remarks / notes")


class PaymentUpdate(BaseModel):
    amount: Optional[int] = Field(None, gt=0)
    mode: Optional[PaymentMode] = None
    reference_no: Optional[str] = None
    paid_on: Optional[datetime] = None
    remarks: Optional[str] = None


class PaymentRejectRequest(BaseModel):
    reason: str = Field(..., min_length=3, description="Mandatory rejection reason")


class PaymentRead(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    stage_no: int
    amount: int
    mode: PaymentMode
    reference_no: Optional[str] = None
    paid_on: datetime
    proof_key: Optional[str] = None
    proof_url: Optional[str] = None
    status: PaymentStatus
    submitted_by: uuid.UUID
    submitted_by_role: UserRole
    sales_approved_by: Optional[uuid.UUID] = None
    sales_approved_at: Optional[datetime] = None
    verified_by: Optional[uuid.UUID] = None
    verified_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    remarks: Optional[str] = None
    is_deleted: bool
    created_at: datetime
    updated_at: datetime
    submitter: Optional[UserRead] = None
    sales_approver: Optional[UserRead] = None
    verifier: Optional[UserRead] = None
    audit_logs: Optional[List[PaymentAuditLogRead]] = None

    class Config:
        from_attributes = True


class PaymentSummary(BaseModel):
    final_price: int = Field(..., description="Customer total final price in paise")
    total_verified: int = Field(..., description="Total verified amount in paise")
    total_pending: int = Field(..., description="Total pending + sales approved amount in paise")
    balance: int = Field(..., description="Remaining balance to be verified in paise")
    status: str = Field(..., description="Overall payment status: pending, partially_paid, fully_paid")


class CustomerPaymentsListResponse(BaseModel):
    items: List[PaymentRead]
    summary: PaymentSummary
