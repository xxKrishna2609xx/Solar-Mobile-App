from datetime import datetime
from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import KedlDemandStatus, KedlFileStatus, KedlFileType, UserRole
from app.models.user import User
from app.schemas.kedl import (
    KedlDashboardMetrics,
    KedlDemandCreate,
    KedlDemandRead,
    KedlDemandUpdate,
    KedlDocumentRead,
    KedlFileInitRequest,
    KedlFileRead,
    KedlFileStatusUpdate,
    KedlFileUpdate,
)
from app.services.kedl_service import KedlService

router = APIRouter(tags=["KEDL Tracker"])


@router.post(
    "/customers/{customer_id}/kedl-files/init",
    response_model=List[KedlFileRead],
    status_code=status.HTTP_201_CREATED,
    summary="Initialize Name Change, Load, and Net files for customer (Admin or KEDL)",
)
async def init_kedl_files(
    customer_id: uuid.UUID,
    payload: KedlFileInitRequest = KedlFileInitRequest(),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.init_customer_files(
        db=db,
        customer_id=customer_id,
        init_in=payload,
        current_user=current_user,
    )


@router.get(
    "/kedl-files",
    response_model=List[KedlFileRead],
    status_code=status.HTTP_200_OK,
    summary="List KEDL files with filters (KEDL role scoped to assigned files)",
)
async def list_kedl_files(
    customer_id: Optional[uuid.UUID] = Query(default=None),
    file_type: Optional[KedlFileType] = Query(default=None),
    status: Optional[KedlFileStatus] = Query(default=None),
    assigned_to: Optional[uuid.UUID] = Query(default=None),
    has_open_demand: Optional[bool] = Query(default=None),
    search: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.list_kedl_files(
        db=db,
        current_user=current_user,
        customer_id=customer_id,
        file_type=file_type,
        status=status,
        assigned_to=assigned_to,
        has_open_demand=has_open_demand,
        search=search,
    )


@router.get(
    "/kedl/dashboard",
    response_model=KedlDashboardMetrics,
    status_code=status.HTTP_200_OK,
    summary="Get KEDL paperwork dashboard counts and demand metrics",
)
async def get_kedl_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.get_dashboard_metrics(
        db=db,
        current_user=current_user,
    )


@router.get(
    "/kedl-files/{file_id}",
    response_model=KedlFileRead,
    status_code=status.HTTP_200_OK,
    summary="Get KEDL file details with demands, documents, and status logs",
)
async def get_kedl_file(
    file_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.get_kedl_file_by_id(
        db=db,
        file_id=file_id,
        current_user=current_user,
    )


@router.patch(
    "/kedl-files/{file_id}",
    response_model=KedlFileRead,
    status_code=status.HTTP_200_OK,
    summary="Update KEDL file application number, remarks, or assignee",
)
async def update_kedl_file(
    file_id: uuid.UUID,
    payload: KedlFileUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.update_kedl_file(
        db=db,
        file_id=file_id,
        file_in=payload,
        current_user=current_user,
    )


@router.post(
    "/kedl-files/{file_id}/status",
    response_model=KedlFileRead,
    status_code=status.HTTP_200_OK,
    summary="Update KEDL file status (Net file approval auto-advances to SYSTEM_LIVE)",
)
async def update_file_status(
    file_id: uuid.UUID,
    payload: KedlFileStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.update_file_status(
        db=db,
        file_id=file_id,
        status_in=payload,
        current_user=current_user,
    )


@router.post(
    "/kedl-files/{file_id}/demands",
    response_model=KedlDemandRead,
    status_code=status.HTTP_201_CREATED,
    summary="Raise a demand requirement on a KEDL file (sets status to demand_raised)",
)
async def raise_demand(
    file_id: uuid.UUID,
    payload: KedlDemandCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    return await KedlService.raise_demand(
        db=db,
        file_id=file_id,
        demand_in=payload,
        current_user=current_user,
    )


@router.patch(
    "/kedl-demands/{demand_id}",
    response_model=KedlDemandRead,
    status_code=status.HTTP_200_OK,
    summary="Mark demand as paid or waived with optional payment receipt",
)
async def update_demand(
    demand_id: uuid.UUID,
    status: KedlDemandStatus = Form(..., description="paid or waived"),
    paid_on: Optional[datetime] = Form(None),
    receipt_file: Optional[UploadFile] = File(None, description="Optional payment receipt upload"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    receipt_stream = None
    receipt_filename = None
    receipt_mime = None

    if receipt_file:
        receipt_stream = receipt_file.file
        receipt_filename = receipt_file.filename
        receipt_mime = receipt_file.content_type

    demand_in = KedlDemandUpdate(status=status, paid_on=paid_on)
    return await KedlService.update_demand(
        db=db,
        demand_id=demand_id,
        demand_in=demand_in,
        current_user=current_user,
        receipt_file=receipt_stream,
        receipt_filename=receipt_filename,
        receipt_content_type=receipt_mime,
    )


@router.post(
    "/kedl-files/{file_id}/documents",
    response_model=KedlDocumentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a document for a KEDL file (application copy, inspection report, etc.)",
)
async def upload_kedl_document(
    file_id: uuid.UUID,
    doc_type: str = Form("other", description="Document type tag"),
    file: UploadFile = File(..., description="Document file to upload"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.KEDL)),
):
    content = await file.read()
    size_bytes = len(content)
    file_stream = file.file
    await file.seek(0)

    return await KedlService.upload_document(
        db=db,
        file_id=file_id,
        doc_type=doc_type,
        file_obj=file_stream,
        filename=file.filename or f"kedl_doc_{uuid.uuid4()}",
        content_type=file.content_type or "application/octet-stream",
        size_bytes=size_bytes,
        current_user=current_user,
    )
