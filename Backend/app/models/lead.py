import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional
from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import LeadStatus

if TYPE_CHECKING:
    from app.models.customer import Customer
    from app.models.user import User


class Lead(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "leads"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str] = mapped_column(String(20), index=True, nullable=False)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    expected_kw: Mapped[Optional[float]] = mapped_column(Numeric(6, 2), nullable=True)
    source: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    status: Mapped[LeadStatus] = mapped_column(
        Enum(LeadStatus, name="lead_status_enum", native_enum=False),
        default=LeadStatus.NEW,
        nullable=False,
        index=True,
    )
    follow_up_date: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    assigned_sales_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    customer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    lost_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    assigned_sales: Mapped["User"] = relationship("User", foreign_keys=[assigned_sales_id], lazy="joined")
    customer: Mapped[Optional["Customer"]] = relationship("Customer", foreign_keys=[customer_id], lazy="joined")
