import uuid
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import BigInteger, DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import PaymentAction, PaymentMode, PaymentStatus, UserRole

if TYPE_CHECKING:
    from app.models.customer import Customer
    from app.models.user import User


class Payment(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "payments"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    stage_no: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    amount: Mapped[int] = mapped_column(BigInteger, nullable=False, comment="Amount in paise")
    mode: Mapped[PaymentMode] = mapped_column(
        Enum(PaymentMode, name="payment_mode_enum", native_enum=False),
        nullable=False,
    )
    reference_no: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    paid_on: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    proof_key: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status_enum", native_enum=False),
        default=PaymentStatus.PENDING,
        nullable=False,
        index=True,
    )

    submitted_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    submitted_by_role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role_enum", native_enum=False),
        nullable=False,
    )

    sales_approved_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    sales_approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    verified_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    rejection_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    remarks: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", lazy="joined")
    submitter: Mapped["User"] = relationship("User", foreign_keys=[submitted_by], lazy="joined")
    sales_approver: Mapped[Optional["User"]] = relationship("User", foreign_keys=[sales_approved_by], lazy="joined")
    verifier: Mapped[Optional["User"]] = relationship("User", foreign_keys=[verified_by], lazy="joined")
    audit_logs: Mapped[List["PaymentAuditLog"]] = relationship(
        "PaymentAuditLog",
        back_populates="payment",
        cascade="all, delete-orphan",
        order_by="PaymentAuditLog.created_at.desc()",
        lazy="selectin",
    )


class PaymentAuditLog(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "payment_audit_logs"

    payment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("payments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    action: Mapped[PaymentAction] = mapped_column(
        Enum(PaymentAction, name="payment_action_enum", native_enum=False),
        nullable=False,
    )
    actor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    old_status: Mapped[Optional[PaymentStatus]] = mapped_column(
        Enum(PaymentStatus, name="payment_status_enum", native_enum=False),
        nullable=True,
    )
    new_status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status_enum", native_enum=False),
        nullable=False,
    )
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    payment: Mapped["Payment"] = relationship("Payment", back_populates="audit_logs")
    actor: Mapped[Optional["User"]] = relationship("User", lazy="joined")
