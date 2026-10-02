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
    "/customers/{customer_id}/work-assignments",
    response_model=WorkAssignmentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Assign installation work to a team with dates (Admin only)",
)
async def create_work_assignment(
    customer_id: uuid.UUID,
    payload: WorkAssignmentCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await WorkAssignmentService.create_work_assignment(
        db=db,
        customer_id=customer_id,
        assignment_in=payload,
        admin_user=admin_user,
    )


@router.get(
    "/work-assignments",
    response_model=List[WorkAssignmentRead],
    status_code=status.HTTP_200_OK,
    summary="List work assignments with filters (Labour scoped to own team)",
)
async def list_work_assignments(
    customer_id: Optional[uuid.UUID] = Query(default=None),
    team_id: Optional[uuid.UUID] = Query(default=None),
    work_type: Optional[WorkType] = Query(default=None),
    status: Optional[WorkStatus] = Query(default=None),
    date_from: Optional[date] = Query(default=None),
    date_to: Optional[date] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await WorkAssignmentService.list_work_assignments(
        db=db,
        current_user=current_user,
        customer_id=customer_id,
        team_id=team_id,
        work_type=work_type,
        status=status,
        date_from=date_from,
        date_to=date_to,
    )


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
    response_model=WorkAssignmentRead,
    status_code=status.HTTP_200_OK,
    summary="Update or reschedule work assignment (Admin only)",
)
async def update_work_assignment(
    assignment_id: uuid.UUID,
    payload: WorkAssignmentUpdate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await WorkAssignmentService.update_work_assignment(
        db=db,
        assignment_id=assignment_id,
        update_in=payload,
        admin_user=admin_user,
    )


@router.post(
    "/work-assignments/{assignment_id}/start",
    response_model=WorkAssignmentRead,
    status_code=status.HTTP_200_OK,
    summary="Mark work as started (Team member or Admin)",
)
async def start_work(
    assignment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await WorkAssignmentService.start_work(
        db=db,
        assignment_id=assignment_id,
        current_user=current_user,
    )


@router.post(
    "/work-assignments/{assignment_id}/photos",
    response_model=List[WorkPhotoRead],
    status_code=status.HTTP_201_CREATED,
    summary="Upload completion or progress photos for work assignment",
)
async def upload_photos(
    assignment_id: uuid.UUID,
    files: List[UploadFile] = File(..., description="1 to 10 photo files"),
    captions: Optional[List[str]] = Form(None, description="Optional caption per file"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    file_streams = []
    filenames = []
    content_types = []

    for f in files:
        file_streams.append(f.file)
        filenames.append(f.filename or f"photo_{uuid.uuid4()}")
        content_types.append(f.content_type or "image/jpeg")

    padded_captions: List[Optional[str]] = []
    if captions:
        for idx in range(len(files)):
            padded_captions.append(captions[idx] if idx < len(captions) else None)
    else:
        padded_captions = [None] * len(files)

    return await WorkAssignmentService.upload_photos(
        db=db,
        assignment_id=assignment_id,
        files=file_streams,
        filenames=filenames,
        content_types=content_types,
        captions=padded_captions,
        current_user=current_user,
    )


@router.post(
    "/work-assignments/{assignment_id}/complete",
    response_model=WorkAssignmentRead,
    status_code=status.HTTP_200_OK,
    summary="Mark work as completed (requires at least 1 photo uploaded)",
)
async def complete_work(
    assignment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await WorkAssignmentService.complete_work(
        db=db,
        assignment_id=assignment_id,
        current_user=current_user,
    )
