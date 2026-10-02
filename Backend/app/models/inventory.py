from datetime import datetime
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy import (
    JSON,
    BigInteger,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel, SoftDeleteMixin, TimestampMixin
from app.models.enums import ItemCategory, ItemUnit, SerialStatus, StockMovementType


class Supplier(BaseModel, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "suppliers"

    name: Mapped[str] = mapped_column(String(150), nullable=False, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gst_no: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    stock_movements: Mapped[List["StockMovement"]] = relationship(
        "StockMovement", back_populates="supplier", cascade="all"
    )
    serials: Mapped[List["SerialItem"]] = relationship(
        "SerialItem", back_populates="supplier", cascade="all"
    )


class InventoryItem(BaseModel, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "inventory_items"

    category: Mapped[ItemCategory] = mapped_column(
        Enum(ItemCategory, name="itemcategory"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(150), nullable=False, index=True)
    brand: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    model: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    unit: Mapped[ItemUnit] = mapped_column(
        Enum(ItemUnit, name="itemunit"), default=ItemUnit.PCS, nullable=False
    )
    has_serial: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    min_stock: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    stock_qty: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    specs: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    movements: Mapped[List["StockMovement"]] = relationship(
        "StockMovement", back_populates="item", cascade="all"
    )
    serials: Mapped[List["SerialItem"]] = relationship(
        "SerialItem", back_populates="item", cascade="all"
    )
    planned_allocations: Mapped[List["PlannedMaterial"]] = relationship(
        "PlannedMaterial", back_populates="item", cascade="all"
    )


class StockMovement(BaseModel):
    __tablename__ = "stock_movements"

    item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False, index=True
    )
    type: Mapped[StockMovementType] = mapped_column(
        Enum(StockMovementType, name="stockmovementtype"), nullable=False, index=True
    )
    qty: Mapped[int] = mapped_column(Integer, nullable=False)
    supplier_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("suppliers.id", ondelete="SET NULL"), nullable=True, index=True
    )
    customer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("customers.id", ondelete="SET NULL"), nullable=True, index=True
    )
    unit_cost: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)  # in paise
    invoice_no: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    moved_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    moved_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=func.now(), nullable=False
    )

    item: Mapped["InventoryItem"] = relationship("InventoryItem", back_populates="movements")
    supplier: Mapped[Optional["Supplier"]] = relationship("Supplier", back_populates="stock_movements")
    customer: Mapped[Optional["Customer"]] = relationship("Customer")  # type: ignore # noqa: F821
    mover: Mapped["User"] = relationship("User")  # type: ignore # noqa: F821


class SerialItem(BaseModel, TimestampMixin):
    __tablename__ = "serial_items"
    __table_args__ = (
        UniqueConstraint("item_id", "serial_no", name="uq_item_serial_no"),
    )

    item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False, index=True
    )
    serial_no: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    status: Mapped[SerialStatus] = mapped_column(
        Enum(SerialStatus, name="serialstatus"), default=SerialStatus.IN_STOCK, nullable=False, index=True
    )
    customer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("customers.id", ondelete="SET NULL"), nullable=True, index=True
    )
    supplier_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("suppliers.id", ondelete="SET NULL"), nullable=True, index=True
    )
    warranty_months: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    warranty_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    installed_on: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    item: Mapped["InventoryItem"] = relationship("InventoryItem", back_populates="serials")
    customer: Mapped[Optional["Customer"]] = relationship("Customer")  # type: ignore # noqa: F821
    supplier: Mapped[Optional["Supplier"]] = relationship("Supplier", back_populates="serials")


class PlannedMaterial(BaseModel):
    __tablename__ = "planned_materials"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("customers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    item_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False, index=True
    )
    qty: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=func.now(), nullable=False
    )

    customer: Mapped["Customer"] = relationship("Customer")  # type: ignore # noqa: F821
    item: Mapped["InventoryItem"] = relationship("InventoryItem", back_populates="planned_allocations")
