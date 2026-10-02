import uuid
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import BigInteger, DateTime, Enum, Float, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import CustomerStage, SystemPhase

if TYPE_CHECKING:
    from app.models.document import CustomerDocument
    from app.models.user import User


class Customer(Base, UUIDPrimaryKeyMixin, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "customers"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    mobile: Mapped[str] = mapped_column(String(20), unique=True, index=True, nullable=False)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    sales_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    final_price: Mapped[int] = mapped_column(BigInteger, nullable=False, comment="Final price in paise")
    capacity_kw: Mapped[float] = mapped_column(Numeric(6, 2), nullable=False)
    phase: Mapped[SystemPhase] = mapped_column(
        Enum(SystemPhase, name="system_phase_enum", native_enum=False),
        nullable=False,
    )
    panel_brand: Mapped[str] = mapped_column(String(100), nullable=False)
    panel_watt: Mapped[int] = mapped_column(Integer, nullable=False)
    panel_count: Mapped[int] = mapped_column(Integer, nullable=False)
    inverter_brand: Mapped[str] = mapped_column(String(100), nullable=False)
    structure_type: Mapped[str] = mapped_column(String(100), nullable=False)

    stage: Mapped[CustomerStage] = mapped_column(
        Enum(CustomerStage, name="customer_stage_enum", native_enum=False),
        default=CustomerStage.SALE_CONFIRMED,
        nullable=False,
        index=True,
    )
    sale_closed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    sales_agent: Mapped["User"] = relationship("User", foreign_keys=[sales_id], lazy="joined")
    client_user: Mapped["User"] = relationship("User", foreign_keys=[user_id], lazy="joined")
    documents: Mapped[List["CustomerDocument"]] = relationship(
        "CustomerDocument",
        back_populates="customer",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    stage_histories: Mapped[List["StageHistory"]] = relationship(
        "StageHistory",
        back_populates="customer",
        cascade="all, delete-orphan",
        order_by="StageHistory.created_at.desc()",
        lazy="selectin",
    )


class StageHistory(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "stage_histories"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    from_stage: Mapped[Optional[CustomerStage]] = mapped_column(
        Enum(CustomerStage, name="customer_stage_enum", native_enum=False),
        nullable=True,
    )
    to_stage: Mapped[CustomerStage] = mapped_column(
        Enum(CustomerStage, name="customer_stage_enum", native_enum=False),
        nullable=False,
    )
    changed_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", back_populates="stage_histories")
    actor: Mapped[Optional["User"]] = relationship("User", lazy="joined")
