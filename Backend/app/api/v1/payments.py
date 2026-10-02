from datetime import datetime
from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import PaymentMode, UserRole
from app.models.user import User
from app.schemas.payment import (
    CustomerPaymentsListResponse,
    PaymentCreate,
    PaymentRead,
    PaymentRejectRequest,
    PaymentUpdate,
)
from app.services.payment_service import PaymentService

router = APIRouter(tags=["Payments"])


@router.post(
    "/customers/{customer_id}/payments",
    response_model=PaymentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Record or submit a customer payment with optional photo proof",
)
async def create_payment(
    customer_id: uuid.UUID,
    amount: int = Form(..., gt=0, description="Amount in paise"),
    mode: PaymentMode = Form(..., description="Payment mode"),
    reference_no: Optional[str] = Form(None, description="Transaction or cheque reference"),
    paid_on: Optional[datetime] = Form(None, description="Payment timestamp"),
    remarks: Optional[str] = Form(None, description="Remarks or notes"),
    direct_verify: bool = Form(False, description="Admin only: immediately mark as verified"),
    file: Optional[UploadFile] = File(None, description="Optional payment proof image/receipt"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    payment_in = PaymentCreate(
        amount=amount,
        mode=mode,
        reference_no=reference_no,
        paid_on=paid_on or datetime.utcnow(),
        remarks=remarks,
    )

    proof_stream = None
    proof_filename = None
    proof_mime = None
    proof_size = None

    if file:
        content = await file.read()
        proof_size = len(content)
        proof_stream = file.file
        proof_filename = file.filename
        proof_mime = file.content_type
        await file.seek(0)

    return await PaymentService.create_payment(
        db=db,
        customer_id=customer_id,
        payment_in=payment_in,
        current_user=current_user,
        proof_file=proof_stream,
        proof_filename=proof_filename,
        proof_content_type=proof_mime,
        proof_size=proof_size,
        direct_verify=direct_verify,
    )


@router.get(
    "/customers/{customer_id}/payments",
    response_model=CustomerPaymentsListResponse,
    status_code=status.HTTP_200_OK,
    summary="List customer payments with full financial summary",
)
async def get_customer_payments(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await PaymentService.get_customer_payments(
        db=db,
        customer_id=customer_id,
        current_user=current_user,
    )


@router.get(
    "/payments/pending",
    response_model=List[PaymentRead],
    status_code=status.HTTP_200_OK,
    summary="List pending approval payments queue (Sales queue or Admin queue)",
)
async def list_pending_payments(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await PaymentService.list_pending_payments(
        db=db,
        current_user=current_user,
    )


@router.post(
    "/payments/{payment_id}/sales-approve",
    response_model=PaymentRead,
    status_code=status.HTTP_200_OK,
    summary="Sales agent (or admin) approves customer payment submission",
)
async def sales_approve_payment(
    payment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await PaymentService.sales_approve_payment(
        db=db,
        payment_id=payment_id,
        current_user=current_user,
    )


@router.post(
    "/payments/{payment_id}/verify",
    response_model=PaymentRead,
    status_code=status.HTTP_200_OK,
    summary="Admin confirms and verifies received payment into company account",
)
async def verify_payment(
    payment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await PaymentService.verify_payment(
        db=db,
        payment_id=payment_id,
        admin_user=admin_user,
    )


@router.post(
    "/payments/{payment_id}/reject",
    response_model=PaymentRead,
    status_code=status.HTTP_200_OK,
    summary="Reject payment with mandatory explanation",
)
async def reject_payment(
    payment_id: uuid.UUID,
    payload: PaymentRejectRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await PaymentService.reject_payment(
        db=db,
        payment_id=payment_id,
        reason=payload.reason,
        current_user=current_user,
    )


@router.patch(
    "/payments/{payment_id}",
    response_model=PaymentRead,
    status_code=status.HTTP_200_OK,
    summary="Update payment details (only allowed while pending)",
)
async def update_payment(
    payment_id: uuid.UUID,
    payload: PaymentUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await PaymentService.update_payment(
        db=db,
        payment_id=payment_id,
        payment_in=payload,
        current_user=current_user,
    )
