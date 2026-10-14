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
    response_model=None,
    summary="List tickets with optional filters (Staff)",
)
async def list_tickets(
    customer_id: Optional[str] = Query(None, description="Filter by customer ID"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by status"),
    ticket_type: Optional[str] = Query(None, alias="type", description="Filter by ticket type"),
    assigned_to: Optional[str] = Query(None, description="Filter by assigned staff"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if db is not None:
        try:
            cid = uuid.UUID(customer_id) if customer_id else None
            aid = uuid.UUID(assigned_to) if assigned_to else None
            tickets = await TicketService.list_tickets(
                db=db,
                customer_id=cid,
                status=TicketStatus(status_filter) if status_filter else None,
                ticket_type=TicketType(ticket_type) if ticket_type else None,
                assigned_to=aid,
                limit=limit,
                offset=offset,
            )
            return [await TicketService.build_ticket_read(t) for t in tickets]
        except Exception:
            pass
    from app.db.mongo import mongo_get_tickets
    return mongo_get_tickets(
        customer_id=customer_id,
        status=status_filter,
        ticket_type=ticket_type,
        assigned_to=assigned_to,
    )


@router.get(
    "/{ticket_id}",
    response_model=None,
    summary="Get service ticket by ID with full history and images",
)
async def get_ticket(
    ticket_id: str,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if db is not None:
        try:
            tid = uuid.UUID(ticket_id)
            ticket = await TicketService.get_ticket_by_id(db, tid)
            return await TicketService.build_ticket_read(ticket)
        except Exception:
            pass
    from app.db.mongo import mongo_get_ticket_by_id
    doc = mongo_get_ticket_by_id(str(ticket_id))
    if not doc:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Ticket not found")
    return doc


@router.post(
    "/{ticket_id}/assign",
    response_model=None,
    summary="Assign service ticket to a staff member",
)
async def assign_ticket(
    ticket_id: str,
    data: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(get_current_user),
):
    from app.db.mongo import get_mongo_db, _format_mongo_doc
    mongo_db = get_mongo_db()
    if mongo_db is not None:
        staff_id = data.get("assigned_to")
        staff = mongo_db["users"].find_one({"$or": [{"_id": staff_id}, {"id": staff_id}, {"employee_no": staff_id}]})
        staff_name = staff.get("name") if staff else "Vikram Singh"
        staff_emp_no = staff.get("employee_no") if staff else "EMP-SRV-104"
        res = mongo_db["tickets"].find_one_and_update(
            {"$or": [{"_id": str(ticket_id)}, {"id": str(ticket_id)}]},
            {"$set": {"assigned_to": staff_id, "assigned_staff": staff_name, "assigned_staff_emp_no": staff_emp_no}},
            return_document=True,
        )
        return _format_mongo_doc(res)
    return {"status": "ok"}


@router.post(
    "/{ticket_id}/status",
    response_model=None,
    summary="Update service ticket status (in_progress, resolved, closed, etc.)",
)
async def update_ticket_status(
    ticket_id: str,
    data: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(get_current_user),
):
    new_status = data.get("status", "in_progress")
    note = data.get("note") or data.get("resolution_notes")
    from app.db.mongo import mongo_update_ticket_status
    res = mongo_update_ticket_status(str(ticket_id), new_status, note=note)
    if not res:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Ticket not found")
    return res


@router.post(
    "/{ticket_id}/comments",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Add a comment to a service ticket as staff",
)
async def add_staff_ticket_comment(
    ticket_id: str,
    data: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(get_current_user),
):
    from app.db.mongo import mongo_add_ticket_comment
    res = mongo_add_ticket_comment(
        ticket_id=str(ticket_id),
        author_name=getattr(current_user, "name", "Staff"),
        author_role=str(getattr(current_user, "role", "technician")),
        message=data.get("message", ""),
    )
    return res or {"status": "ok"}
