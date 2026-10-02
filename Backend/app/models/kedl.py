from datetime import date, datetime
from typing import TYPE_CHECKING, List, Optional
import uuid
from sqlalchemy import (
    BigInteger,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import KedlDemandStatus, KedlFileStatus, KedlFileType

if TYPE_CHECKING:
    from app.models.customer import Customer
    from app.models.user import User


class KedlFile(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "kedl_files"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    file_type: Mapped[KedlFileType] = mapped_column(
        Enum(KedlFileType, name="kedl_file_type_enum", native_enum=False),
        nullable=False,
        index=True,
    )
    status: Mapped[KedlFileStatus] = mapped_column(
        Enum(KedlFileStatus, name="kedl_file_status_enum", native_enum=False),
        default=KedlFileStatus.NOT_STARTED,
        nullable=False,
        index=True,
    )
    application_no: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    submitted_on: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    approved_on: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    assigned_to: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    remarks: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", lazy="joined")
    assignee: Mapped[Optional["User"]] = relationship("User", foreign_keys=[assigned_to], lazy="joined")
    demands: Mapped[List["KedlDemand"]] = relationship(
        "KedlDemand",
        back_populates="kedl_file",
        cascade="all, delete-orphan",
        order_by="KedlDemand.raised_on.desc()",
        lazy="selectin",
    )
    documents: Mapped[List["KedlDocument"]] = relationship(
        "KedlDocument",
        back_populates="kedl_file",
        cascade="all, delete-orphan",
        order_by="KedlDocument.created_at.desc()",
        lazy="selectin",
    )
    status_logs: Mapped[List["KedlStatusLog"]] = relationship(
        "KedlStatusLog",
        back_populates="kedl_file",
        cascade="all, delete-orphan",
        order_by="KedlStatusLog.created_at.desc()",
        lazy="selectin",
    )

    __table_args__ = (
        UniqueConstraint("customer_id", "file_type", name="uq_customer_kedl_file_type"),
    )


class KedlDemand(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "kedl_demands"

    kedl_file_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("kedl_files.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True, comment="Demand fee in paise if applicable")
    due_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    status: Mapped[KedlDemandStatus] = mapped_column(
        Enum(KedlDemandStatus, name="kedl_demand_status_enum", native_enum=False),
        default=KedlDemandStatus.OPEN,
        nullable=False,
        index=True,
    )
    paid_on: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    receipt_key: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    raised_on: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    raised_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationships
    kedl_file: Mapped["KedlFile"] = relationship("KedlFile", back_populates="demands")
    raiser: Mapped[Optional["User"]] = relationship("User", foreign_keys=[raised_by], lazy="joined")


class KedlDocument(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "kedl_documents"

    kedl_file_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("kedl_files.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    doc_type: Mapped[str] = mapped_column(String(50), default="other", nullable=False)
    file_key: Mapped[str] = mapped_column(String(255), nullable=False)
    original_name: Mapped[str] = mapped_column(String(255), nullable=False)
    uploaded_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationships
    kedl_file: Mapped["KedlFile"] = relationship("KedlFile", back_populates="documents")
    uploader: Mapped[Optional["User"]] = relationship("User", foreign_keys=[uploaded_by], lazy="joined")


class KedlStatusLog(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "kedl_status_logs"

    kedl_file_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("kedl_files.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    from_status: Mapped[Optional[KedlFileStatus]] = mapped_column(
        Enum(KedlFileStatus, name="kedl_file_status_enum", native_enum=False),
        nullable=True,
    )
    to_status: Mapped[KedlFileStatus] = mapped_column(
        Enum(KedlFileStatus, name="kedl_file_status_enum", native_enum=False),
        nullable=False,
    )
    changed_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    kedl_file: Mapped["KedlFile"] = relationship("KedlFile", back_populates="status_logs")
    actor: Mapped[Optional["User"]] = relationship("User", foreign_keys=[changed_by], lazy="joined")
