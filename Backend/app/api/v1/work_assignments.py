from datetime import date
from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import UserRole, WorkStatus, WorkType
from app.models.user import User
from app.schemas.work_assignment import (
    CalendarScheduleResponse,
    WorkAssignmentCreate,
    WorkAssignmentRead,
    WorkAssignmentUpdate,
    WorkPhotoRead,
)
from app.services.work_assignment_service import WorkAssignmentService

router = APIRouter(tags=["Work Assignments"])


@router.post(
    "/work-assignments",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Assign installation work to a team with dates (Notebook Page 2)",
)
async def create_work_assignment_direct(
    payload: dict,
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import mongo_create_work_assignment
    return mongo_create_work_assignment(payload)


@router.post(
    "/customers/{customer_id}/work-assignments",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Assign installation work to a team with dates",
)
async def create_work_assignment(
    customer_id: str,
    payload: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    admin_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    payload["customer_id"] = str(customer_id)
    from app.db.mongo import mongo_create_work_assignment
    return mongo_create_work_assignment(payload)


@router.get(
    "/work-assignments",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="List work assignments with filters (Structure, Electrical, Civil)",
)
async def list_work_assignments(
    customer_id: Optional[str] = Query(default=None),
    work_type: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    current_user=Depends(get_current_user),
):
    from app.db.mongo import mongo_get_work_assignments
    return mongo_get_work_assignments(customer_id=customer_id, work_type=work_type)



@router.get(
    "/work-assignments/calendar",
    response_model=CalendarScheduleResponse,
    status_code=status.HTTP_200_OK,
    summary="Calendar view of assignments grouped by date and by team",
)
async def get_calendar_schedule(
    from_date: date = Query(..., description="Start date (YYYY-MM-DD)"),
    to_date: date = Query(..., description="End date (YYYY-MM-DD)"),
    team_id: Optional[uuid.UUID] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await WorkAssignmentService.get_calendar_schedule(
        db=db,
        from_date=from_date,
        to_date=to_date,
        current_user=current_user,
        team_id=team_id,
    )


@router.get(
    "/work-assignments/{assignment_id}",
    response_model=WorkAssignmentRead,
    status_code=status.HTTP_200_OK,
    summary="Get work assignment details by ID",
)
async def get_work_assignment(
    assignment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await WorkAssignmentService.get_work_assignment_by_id(
        db=db,
        assignment_id=assignment_id,
        current_user=current_user,
    )


@router.patch(
    "/work-assignments/{assignment_id}",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Update or reschedule work assignment (Admin or Vendor)",
)
async def update_work_assignment(
    assignment_id: str,
    payload: dict,
    db: Optional[AsyncSession] = Depends(get_db),
    admin_user=Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    from app.db.mongo import mongo_update_work_assignment
    res = mongo_update_work_assignment(str(assignment_id), payload)
    if not res:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Work assignment not found")
    return res


@router.post(
    "/work-assignments/{assignment_id}/start",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Mark work as started",
)
async def start_work(
    assignment_id: str,
    current_user=Depends(get_current_user),
):
    from app.db.mongo import mongo_update_work_assignment
    return mongo_update_work_assignment(str(assignment_id), {"status": "in_progress"})


@router.post(
    "/work-assignments/{assignment_id}/complete",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Mark work as completed",
)
async def complete_work(
    assignment_id: str,
    current_user=Depends(get_current_user),
):
    from app.db.mongo import mongo_update_work_assignment
    return mongo_update_work_assignment(str(assignment_id), {"status": "completed"})

