import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import CustomerStage, DocumentType, UserRole
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.customer import (
    CustomerCreate,
    CustomerRead,
    CustomerStageUpdate,
    CustomerUpdate,
)
from app.schemas.document import CustomerDocumentRead
from app.services.customer_service import CustomerService
from app.services.document_service import DocumentService

router = APIRouter(prefix="/customers", tags=["Customers"])


@router.post(
    "",
    response_model=CustomerRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new customer (Admin or Sales)",
)
async def create_customer(
    payload: CustomerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await CustomerService.create_customer(
        db=db,
        customer_in=payload,
        creator=current_user,
    )


@router.get(
    "",
    response_model=PaginatedResponse[CustomerRead],
    status_code=status.HTTP_200_OK,
    summary="List customers with filters and role-level isolation",
)
async def list_customers(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    stage: Optional[CustomerStage] = Query(default=None),
    sales_id: Optional[uuid.UUID] = Query(default=None),
    search: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await CustomerService.list_customers(
        db=db,
        current_user=current_user,
        page=page,
        page_size=page_size,
        stage=stage,
        sales_id=sales_id,
        search=search,
    )


@router.get(
    "/{customer_id}",
    response_model=CustomerRead,
    status_code=status.HTTP_200_OK,
    summary="Get customer details by ID",
)
async def get_customer(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await CustomerService.get_customer_by_id(
        db=db,
        customer_id=customer_id,
        current_user=current_user,
    )


@router.patch(
    "/{customer_id}",
    response_model=CustomerRead,
    status_code=status.HTTP_200_OK,
    summary="Update customer details (Admin or assigned Sales)",
)
async def update_customer(
    customer_id: uuid.UUID,
    payload: CustomerUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.SALES)),
):
    return await CustomerService.update_customer(
        db=db,
        customer_id=customer_id,
        customer_in=payload,
        current_user=current_user,
    )


@router.patch(
    "/{customer_id}/stage",
    response_model=CustomerRead,
    status_code=status.HTTP_200_OK,
    summary="Update customer lifecycle stage with history tracking (Admin only)",
)
async def update_customer_stage(
    customer_id: uuid.UUID,
    payload: CustomerStageUpdate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await CustomerService.update_customer_stage(
        db=db,
        customer_id=customer_id,
        stage_in=payload,
        current_user=admin_user,
    )


@router.post(
    "/{customer_id}/documents",
    response_model=CustomerDocumentRead,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a customer document (JPG, PNG, PDF up to 10 MB)",
)
async def upload_document(
    customer_id: uuid.UUID,
    type: DocumentType = Form(..., description="Type of document"),
    file: UploadFile = File(..., description="Document file to upload"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    content = await file.read()
    size_bytes = len(content)
    file_stream = file.file

    # Reset position after reading length
    await file.seek(0)

    return await DocumentService.upload_document(
        db=db,
        customer_id=customer_id,
        doc_type=type,
        file_obj=file_stream,
        filename=file.filename or f"doc_{uuid.uuid4()}",
        content_type=file.content_type or "application/octet-stream",
        size_bytes=size_bytes,
        uploader=current_user,
    )


@router.get(
    "/{customer_id}/documents",
    response_model=List[CustomerDocumentRead],
    status_code=status.HTTP_200_OK,
    summary="List customer documents with short-lived presigned download URLs",
)
async def list_documents(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await DocumentService.list_customer_documents(
        db=db,
        customer_id=customer_id,
        current_user=current_user,
    )
