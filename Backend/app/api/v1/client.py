from datetime import datetime
from typing import List, Optional
import uuid
from fastapi import APIRouter, Body, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.enums import PaymentMode
from app.models.user import User
from app.schemas.client import ClientHomeResponse
from app.schemas.document import DocumentRead
from app.schemas.payment import CustomerPaymentsListResponse, PaymentCreate, PaymentRead
from app.schemas.ticket import TicketCommentCreate, TicketCommentRead, TicketCreate, TicketRead
from app.services.client_service import ClientService
from app.services.document_service import DocumentService
from app.services.payment_service import PaymentService
from app.services.ticket_service import TicketService

router = APIRouter(prefix="/client", tags=["Client Mobile Experience"])


@router.get(
    "/home",
    response_model=ClientHomeResponse,
    summary="Get customer home screen data including 10-stage timeline, contacts, specs, and payments",
)
async def get_client_home(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await ClientService.get_home_data(db, current_user)


@router.get(
    "/payments",
    response_model=CustomerPaymentsListResponse,
    summary="Get all payment records and schedule status for the logged-in client",
)
async def get_client_payments(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    return await PaymentService.get_customer_payments(db, customer.id)


@router.post(
    "/payments",
    response_model=PaymentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a payment receipt / record as client",
)
async def submit_client_payment(
    amount: int = Form(..., gt=0, description="Amount in paise"),
    mode: PaymentMode = Form(..., description="Payment mode"),
    reference_no: Optional[str] = Form(None, description="Transaction reference"),
    paid_on: Optional[datetime] = Form(None, description="Payment date"),
    remarks: Optional[str] = Form(None, description="Remarks"),
    file: Optional[UploadFile] = File(None, description="Optional receipt proof file"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
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

    payment = await PaymentService.record_payment(
        db=db,
        customer_id=customer.id,
        data=payment_in,
        current_user=current_user,
        proof_file=proof_stream,
        filename=proof_filename,
        content_type=proof_mime,
        file_size=proof_size,
    )
    return await PaymentService.build_payment_read(payment)


@router.get(
    "/documents",
    response_model=List[DocumentRead],
    summary="List all uploaded KYC and project documents for the client",
)
async def get_client_documents(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    docs = await DocumentService.get_customer_documents(db, customer.id)
    return [await DocumentService.build_document_read(doc) for doc in docs]


@router.post(
    "/tickets",
    response_model=TicketRead,
    status_code=status.HTTP_201_CREATED,
    summary="Raise a new post-installation service ticket",
)
async def create_client_ticket(
    data: TicketCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    ticket = await TicketService.create_ticket(db, customer, data, current_user)
    return await TicketService.build_ticket_read(ticket)


@router.get(
    "/tickets",
    response_model=List[TicketRead],
    summary="List all service tickets raised for the logged-in client",
)
async def list_client_tickets(
    limit: int = 50,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    tickets = await TicketService.list_tickets(
        db=db,
        customer_id=customer.id,
        limit=limit,
        offset=offset,
    )
    return [await TicketService.build_ticket_read(t) for t in tickets]


@router.get(
    "/tickets/{ticket_id}",
    response_model=TicketRead,
    summary="Get service ticket details",
)
async def get_client_ticket(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    ticket = await TicketService.get_ticket_by_id(db, ticket_id, for_customer_id=customer.id)
    return await TicketService.build_ticket_read(ticket)


@router.post(
    "/tickets/{ticket_id}/comments",
    response_model=TicketCommentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Add a comment to a service ticket",
)
async def add_client_ticket_comment(
    ticket_id: uuid.UUID,
    data: TicketCommentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    comment = await TicketService.add_comment(
        db=db,
        ticket_id=ticket_id,
        data=data,
        user=current_user,
        for_customer_id=customer.id,
    )
    return TicketCommentRead(
        id=comment.id,
        ticket_id=comment.ticket_id,
        author_id=comment.author_id,
        author_name=current_user.name,
        author_role=current_user.role.value,
        message=comment.message,
        created_at=comment.created_at,
    )


@router.post(
    "/tickets/{ticket_id}/reopen",
    response_model=TicketRead,
    summary="Reopen a resolved or closed ticket (within 7 days)",
)
async def reopen_client_ticket(
    ticket_id: uuid.UUID,
    reason: str = Body(..., embed=True),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    customer = await ClientService.get_client_customer(db, current_user)
    ticket = await TicketService.reopen_by_client(
        db=db,
        ticket_id=ticket_id,
        reason=reason,
        user=current_user,
        customer_id=customer.id,
    )
    return await TicketService.build_ticket_read(ticket)
