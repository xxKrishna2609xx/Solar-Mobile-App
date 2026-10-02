from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import TicketStatus, TicketType, UserRole
from app.models.user import User
from app.schemas.ticket import (
    TicketAssign,
    TicketCommentCreate,
    TicketCommentRead,
    TicketRead,
    TicketStatusUpdate,
)
from app.services.ticket_service import TicketService

router = APIRouter(prefix="/tickets", tags=["Staff Service Tickets"])


@router.get(
    "",
    response_model=List[TicketRead],
    summary="List tickets with optional filters (Staff)",
)
async def list_tickets(
    customer_id: Optional[uuid.UUID] = Query(None, description="Filter by customer ID"),
    status_filter: Optional[TicketStatus] = Query(None, alias="status", description="Filter by status"),
    ticket_type: Optional[TicketType] = Query(None, alias="type", description="Filter by ticket type"),
    assigned_to: Optional[uuid.UUID] = Query(None, description="Filter by assigned staff"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.OFFICE_STAFF, UserRole.TECHNICIAN)),
):
    tickets = await TicketService.list_tickets(
        db=db,
        customer_id=customer_id,
        status=status_filter,
        ticket_type=ticket_type,
        assigned_to=assigned_to,
        limit=limit,
        offset=offset,
    )
    return [await TicketService.build_ticket_read(t) for t in tickets]


@router.get(
    "/{ticket_id}",
    response_model=TicketRead,
    summary="Get service ticket by ID with full history and images",
)
async def get_ticket(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.OFFICE_STAFF, UserRole.TECHNICIAN)),
):
    ticket = await TicketService.get_ticket_by_id(db, ticket_id)
    return await TicketService.build_ticket_read(ticket)


@router.post(
    "/{ticket_id}/assign",
    response_model=TicketRead,
    summary="Assign service ticket to a staff member",
)
async def assign_ticket(
    ticket_id: uuid.UUID,
    data: TicketAssign,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    ticket = await TicketService.assign_ticket(db, ticket_id, data, current_user)
    return await TicketService.build_ticket_read(ticket)


@router.post(
    "/{ticket_id}/status",
    response_model=TicketRead,
    summary="Update service ticket status (in_progress, resolved, closed, etc.)",
)
async def update_ticket_status(
    ticket_id: uuid.UUID,
    data: TicketStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.OFFICE_STAFF, UserRole.TECHNICIAN)),
):
    ticket = await TicketService.update_status(db, ticket_id, data, current_user)
    return await TicketService.build_ticket_read(ticket)


@router.post(
    "/{ticket_id}/comments",
    response_model=TicketCommentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Add a comment to a service ticket as staff",
)
async def add_staff_ticket_comment(
    ticket_id: uuid.UUID,
    data: TicketCommentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.OFFICE_STAFF, UserRole.TECHNICIAN)),
):
    comment = await TicketService.add_comment(
        db=db,
        ticket_id=ticket_id,
        data=data,
        user=current_user,
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
