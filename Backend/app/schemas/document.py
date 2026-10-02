import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models.enums import DocumentType


class CustomerDocumentRead(BaseModel):
    id: uuid.UUID
    customer_id: uuid.UUID
    type: DocumentType
    file_key: str
    original_name: str
    mime_type: str
    size_bytes: int
    uploaded_by: Optional[uuid.UUID] = None
    download_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


DocumentRead = CustomerDocumentRead

__all__ = ["CustomerDocumentRead", "DocumentRead"]

