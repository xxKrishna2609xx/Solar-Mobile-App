from datetime import datetime
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
import structlog
from app.core.deps import require_roles
from app.core.helpers import paginate_list
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

logger = structlog.get_logger()
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
        except Exception as e:
            logger.debug("sql_create_lead_fallback_to_mongo", error=str(e))
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
        except Exception as e:
            logger.debug("sql_list_leads_fallback_to_mongo", error=str(e))
    from app.db.mongo import mongo_get_leads
    status_str = status.value if hasattr(status, "value") else (str(status) if status else None)
    sales_id_str = str(assigned_sales_id) if assigned_sales_id else None
    leads = mongo_get_leads(status=status_str, search=search, assigned_sales_id=sales_id_str)
    return paginate_list(items=leads, page=page, page_size=page_size)


@router.get(
    "/salespersons",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="List staff available for lead assignment",
)
async def list_salespersons(
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import mongo_get_salespersons
    return mongo_get_salespersons()


@router.get(
    "/sales-closed",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="List closed/converted sales with sales person details",
)
async def list_sales_closed(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import mongo_get_leads
    leads = mongo_get_leads(status="converted")
    return paginate_list(items=leads, page=page, page_size=page_size)


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
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Assign lead to a salesperson",
)
async def reassign_lead(
    lead_id: str,
    payload: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    admin_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    sales_id = str(payload.get("sales_id") or payload.get("assigned_sales_id", ""))
    sales_name = str(payload.get("sales_name") or payload.get("assigned_sales_name", "Sales Person"))
    from app.db.mongo import mongo_assign_lead
    res = mongo_assign_lead(str(lead_id), sales_id, sales_name)
    if not res:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Lead not found")
    return res


@router.post(
    "/{lead_id}/mark-lost",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Mark lead as lost with reason",
)
async def mark_lead_lost(
    lead_id: str,
    payload: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import get_mongo_db
    db_mongo = get_mongo_db()
    if db_mongo is not None:
        db_mongo["leads"].update_one(
            {"$or": [{"_id": str(lead_id)}, {"id": str(lead_id)}]},
            {"$set": {"status": "lost", "lost_reason": payload.get("reason", "Lost")}}
        )
    return {"status": "success", "lead_id": str(lead_id)}


@router.post(
    "/{lead_id}/convert",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Convert lead to confirmed customer (creates customer + closed sale)",
)
async def convert_lead(
    lead_id: str,
    payload: Optional[dict] = None,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import mongo_convert_lead
    res = mongo_convert_lead(str(lead_id), payload or {})
    if not res:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Lead not found")
    return res

