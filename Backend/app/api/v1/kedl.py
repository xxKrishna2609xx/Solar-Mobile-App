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
    "/kedl-files",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Create or update KEDL file (Page 3 requirement)",
)
async def create_or_update_kedl_file(
    payload: dict,
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.KEDL, UserRole.SALES)),
):
    from app.db.mongo import mongo_create_or_update_kedl_file
    return mongo_create_or_update_kedl_file(payload)


@router.post(
    "/customers/{customer_id}/kedl-files/init",
    response_model=None,
    status_code=status.HTTP_201_CREATED,
    summary="Initialize Name Change, Load, and Net files for customer (Page 3 requirement)",
)
async def init_kedl_files(
    customer_id: str,
    payload: Optional[dict] = None,
    db: Optional[AsyncSession] = Depends(get_db),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.KEDL, UserRole.SALES)),
):
    from app.db.mongo import mongo_create_or_update_kedl_file, mongo_get_customer_by_id
    cust = mongo_get_customer_by_id(str(customer_id))
    cust_name = cust.get("name", "Customer") if cust else "Customer"
    location = cust.get("address", "") if cust else ""
    # Init the 3 files specified in Notebook Page 3: Name Change, Load File, Net File
    res = []
    for ftype in ["name_change", "load", "net"]:
        item = mongo_create_or_update_kedl_file({
            "customer_id": str(customer_id),
            "customer_name": cust_name,
            "location": location,
            "file_type": ftype,
            "status": "not_started",
            "demand_amount": 0,
        })
        res.append(item)
    return res


@router.get(
    "/kedl-files",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="List KEDL files with filters",
)
async def list_kedl_files(
    customer_id: Optional[str] = Query(default=None),
    file_type: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.KEDL, UserRole.SALES)),
):
    from app.db.mongo import mongo_get_kedl_files
    return mongo_get_kedl_files(customer_id=customer_id, file_type=file_type)



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
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Update KEDL file status, demand, or remarks",
)
async def update_kedl_file(
    file_id: str,
    payload: dict,
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.KEDL, UserRole.SALES)),
):
    from app.db.mongo import mongo_update_kedl_demand, get_mongo_db, _format_mongo_doc
    if "demand_amount" in payload or "demand_ref" in payload:
        return mongo_update_kedl_demand(
            str(file_id),
            demand_amount=payload.get("demand_amount", 0),
            status=payload.get("status", "demand_raised"),
            demand_ref=payload.get("demand_notice_ref") or payload.get("demand_ref"),
        )
    db = get_mongo_db()
    if db is not None:
        from pymongo import ReturnDocument
        clean = {k: v for k, v in payload.items() if k not in ["_id", "id"]}
        res = db["kedl_files"].find_one_and_update(
            {"$or": [{"_id": str(file_id)}, {"id": str(file_id)}]},
            {"$set": clean},
            return_document=ReturnDocument.AFTER,
        )
        return _format_mongo_doc(res)
    return {"status": "success", "id": str(file_id)}


@router.post(
    "/kedl-files/{file_id}/demands",
    response_model=None,
    status_code=status.HTTP_200_OK,
    summary="Raise or update demand on KEDL file",
)
async def raise_demand(
    file_id: str,
    payload: dict,
    current_user=Depends(require_roles(UserRole.ADMIN, UserRole.KEDL, UserRole.SALES)),
):
    from app.db.mongo import mongo_update_kedl_demand
    amt = int(payload.get("demand_amount") or payload.get("amount") or 0)
    st = payload.get("status", "demand_raised")
    ref = payload.get("demand_notice_ref") or payload.get("notice_no") or payload.get("demand_ref")
    return mongo_update_kedl_demand(str(file_id), demand_amount=amt, status=st, demand_ref=ref)



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
