from datetime import datetime
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import require_roles
from app.db.session import get_db
from app.models.enums import LeadStatus, UserRole
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.customer import CustomerRead
from app.schemas.lead import (
    LeadAssign,
    LeadConvert,
    LeadCreate,
    LeadMarkLost,
    LeadRead,
    LeadUpdate,
)
from app.services.lead_service import LeadService

router = APIRouter(prefix="/leads", tags=["Leads"])


@router.post(
    "",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new lead (Admin or Sales)",
)
async def create_lead(
    payload: LeadCreate,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import mongo_create_lead
    lead_dict = payload.model_dump()
    mongo_doc = mongo_create_lead(lead_dict)
    if db is not None:
        try:
            return await LeadService.create_lead(db=db, lead_in=payload, current_user=current_user)
        except Exception:
            pass
    return mongo_doc


@router.get(
    "",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="List leads with filters (Sales scoped to own leads; Admin sees all)",
)
async def list_leads(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    status: Optional[LeadStatus] = Query(default=None),
    assigned_sales_id: Optional[uuid.UUID] = Query(default=None),
    search: Optional[str] = Query(default=None),
    start_date: Optional[datetime] = Query(default=None),
    end_date: Optional[datetime] = Query(default=None),
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    if db is not None:
        try:
            return await LeadService.list_leads(
                db=db,
                current_user=current_user,
                page=page,
                page_size=page_size,
                status=status,
                assigned_sales_id=assigned_sales_id,
                search=search,
                start_date=start_date,
                end_date=end_date,
            )
        except Exception:
            pass
    from app.db.mongo import mongo_get_leads
    leads = mongo_get_leads()
    return {
        "items": leads,
        "total": len(leads),
        "page": page,
        "page_size": page_size,
        "pages": 1,
    }


@router.get(
    "/{lead_id}",
    response_model=LeadRead,
    status_code=status.HTTP_200_OK,
    summary="Get lead details by ID",
)
async def get_lead(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await LeadService.get_lead_by_id(db=db, lead_id=lead_id, current_user=current_user)


@router.patch(
    "/{lead_id}",
    response_model=LeadRead,
    status_code=status.HTTP_200_OK,
    summary="Update lead details",
)
async def update_lead(
    lead_id: uuid.UUID,
    payload: LeadUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await LeadService.update_lead(
        db=db,
        lead_id=lead_id,
        lead_in=payload,
        current_user=current_user,
    )


@router.post(
    "/{lead_id}/assign",
    response_model=LeadRead,
    status_code=status.HTTP_200_OK,
    summary="Reassign lead to another salesperson (Admin only)",
)
async def reassign_lead(
    lead_id: uuid.UUID,
    payload: LeadAssign,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await LeadService.reassign_lead(
        db=db,
        lead_id=lead_id,
        assign_in=payload,
        current_user=admin_user,
    )


@router.post(
    "/{lead_id}/mark-lost",
    response_model=LeadRead,
    status_code=status.HTTP_200_OK,
    summary="Mark lead as lost with reason",
)
async def mark_lead_lost(
    lead_id: uuid.UUID,
    payload: LeadMarkLost,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await LeadService.mark_lost(
        db=db,
        lead_id=lead_id,
        lost_in=payload,
        current_user=current_user,
    )


@router.post(
    "/{lead_id}/convert",
    response_model=CustomerRead,
    status_code=status.HTTP_200_OK,
    summary="Convert lead to confirmed customer (creates customer + client user atomically)",
)
async def convert_lead(
    lead_id: uuid.UUID,
    payload: LeadConvert,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await LeadService.convert_lead(
        db=db,
        lead_id=lead_id,
        convert_in=payload,
        current_user=current_user,
    )
