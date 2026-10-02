import io
import mimetypes
import os
import uuid
from typing import BinaryIO, List, Set
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import BadRequestException, ForbiddenException, NotFoundException
from app.models.customer import Customer, StageHistory
from app.models.document import CustomerDocument
from app.models.enums import CustomerStage, DocumentType, UserRole
from app.models.user import User
from app.schemas.document import CustomerDocumentRead
from app.storage.s3 import storage_service

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf"}
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "application/pdf"}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB
MANDATORY_DOC_TYPES: Set[DocumentType] = {
    DocumentType.E_BILL,
    DocumentType.AADHAAR,
    DocumentType.PAN,
    DocumentType.CANCELLED_CHEQUE,
    DocumentType.REGISTRY,
}


class DocumentService:
    """Service handling Customer Document upload, retrieval, and validation."""

    @staticmethod
    async def upload_document(
        db: AsyncSession,
        customer_id: uuid.UUID,
        doc_type: DocumentType,
        file_obj: BinaryIO,
        filename: str,
        content_type: str,
        size_bytes: int,
        uploader: User,
    ) -> CustomerDocumentRead:
        # 1. Fetch customer
        stmt = select(Customer).where(
            Customer.id == customer_id,
            Customer.is_deleted == False,  # noqa: E712
        )
        customer = (await db.execute(stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        # Permissions: Admin or assigned Sales agent
        if uploader.role == UserRole.SALES and customer.sales_id != uploader.id:
            raise ForbiddenException("Sales agents can only upload documents for their own customers.")
        elif uploader.role == UserRole.CLIENT and customer.user_id != uploader.id:
            raise ForbiddenException("Clients can only upload documents for their own account.")

        # 2. Validate file extension and MIME type
        _, ext = os.path.splitext(filename.lower())
        if ext not in ALLOWED_EXTENSIONS:
            raise BadRequestException(f"Unsupported file extension '{ext}'. Allowed: jpg, png, pdf.")

        guessed_type, _ = mimetypes.guess_type(filename)
        effective_mime = content_type or guessed_type or "application/octet-stream"
        if effective_mime not in ALLOWED_MIME_TYPES:
            raise BadRequestException(f"Unsupported content type '{effective_mime}'. Allowed: image/jpeg, image/png, application/pdf.")

        if size_bytes > MAX_FILE_SIZE_BYTES:
            raise BadRequestException(f"File size exceeds maximum allowed limit of 10 MB ({size_bytes} bytes).")

        # 3. Upload to storage
        doc_uuid = uuid.uuid4()
        storage_key = f"customers/{customer_id}/{doc_type.value}/{doc_uuid}{ext}"
        await storage_service.upload_file(
            file_obj=file_obj,
            destination_path=storage_key,
            content_type=effective_mime,
        )

        # 4. Save metadata record
        doc = CustomerDocument(
            id=doc_uuid,
            customer_id=customer_id,
            type=doc_type,
            file_key=storage_key,
            original_name=filename,
            mime_type=effective_mime,
            size_bytes=size_bytes,
            uploaded_by=uploader.id,
        )
        db.add(doc)
        await db.flush()

        # 5. Check mandatory document completion for automatic stage movement
        if customer.stage == CustomerStage.SALE_CONFIRMED:
            # Query all document types for this customer
            all_docs_stmt = select(CustomerDocument.type).where(CustomerDocument.customer_id == customer_id)
            existing_types = set((await db.execute(all_docs_stmt)).scalars().all())
            existing_types.add(doc_type)

            if MANDATORY_DOC_TYPES.issubset(existing_types):
                customer.stage = CustomerStage.DOCUMENTS_RECEIVED
                history = StageHistory(
                    customer_id=customer.id,
                    from_stage=CustomerStage.SALE_CONFIRMED,
                    to_stage=CustomerStage.DOCUMENTS_RECEIVED,
                    changed_by=uploader.id,
                    note="All mandatory documents uploaded (e_bill, aadhaar, pan, cancelled_cheque, registry).",
                )
                db.add(history)

        await db.commit()
        await db.refresh(doc)

        # Generate presigned URL
        presigned_url = await storage_service.get_presigned_url(doc.file_key, expires_in=3600)
        doc_read = CustomerDocumentRead.model_validate(doc)
        doc_read.download_url = presigned_url
        return doc_read

    @staticmethod
    async def list_customer_documents(
        db: AsyncSession,
        customer_id: uuid.UUID,
        current_user: User,
    ) -> List[CustomerDocumentRead]:
        # 1. Fetch customer and check view permissions
        customer_stmt = select(Customer).where(
            Customer.id == customer_id,
            Customer.is_deleted == False,  # noqa: E712
        )
        customer = (await db.execute(customer_stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        if current_user.role == UserRole.SALES and customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only view documents for their own customers.")
        elif current_user.role == UserRole.CLIENT and customer.user_id != current_user.id:
            raise ForbiddenException("Clients can only view their own documents.")

        # 2. Fetch documents
        stmt = select(CustomerDocument).where(CustomerDocument.customer_id == customer_id).order_by(CustomerDocument.created_at.desc())
        docs = list((await db.execute(stmt)).scalars().all())

        results: List[CustomerDocumentRead] = []
        for d in docs:
            read_item = CustomerDocumentRead.model_validate(d)
            read_item.download_url = await storage_service.get_presigned_url(d.file_key, expires_in=3600)
            results.append(read_item)

        return results

    @staticmethod
    async def delete_document(
        db: AsyncSession,
        document_id: uuid.UUID,
        current_user: User,
    ) -> None:
        stmt = select(CustomerDocument).where(CustomerDocument.id == document_id)
        doc = (await db.execute(stmt)).scalar_one_or_none()
        if not doc:
            raise NotFoundException("Document not found.")

        customer_stmt = select(Customer).where(Customer.id == doc.customer_id)
        customer = (await db.execute(customer_stmt)).scalar_one_or_none()

        # Admin, or the uploader while customer stage is before ADVANCE_VERIFIED
        allowed = False
        if current_user.role == UserRole.ADMIN:
            allowed = True
        elif doc.uploaded_by == current_user.id:
            if customer and customer.stage in [CustomerStage.SALE_CONFIRMED, CustomerStage.DOCUMENTS_RECEIVED]:
                allowed = True

        if not allowed:
            raise ForbiddenException("You do not have permission to delete this document or the project stage has advanced beyond document changes.")

        await storage_service.delete_file(doc.file_key)
        await db.delete(doc)
        await db.commit()
