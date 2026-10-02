from datetime import datetime
from typing import Any, Dict, List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import ItemCategory, ItemUnit, SerialStatus, StockMovementType


# Supplier Schemas
class SupplierCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    phone: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = None
    gst_no: Optional[str] = Field(None, max_length=30)


class SupplierUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=150)
    phone: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = None
    gst_no: Optional[str] = Field(None, max_length=30)
    is_active: Optional[bool] = None


class SupplierRead(BaseModel):
    id: uuid.UUID
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    gst_no: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# Inventory Item Schemas
class InventoryItemCreate(BaseModel):
    category: ItemCategory
    name: str = Field(..., min_length=1, max_length=150)
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    unit: ItemUnit = ItemUnit.PCS
    has_serial: bool = False
    min_stock: int = Field(0, ge=0)
    specs: Optional[Dict[str, Any]] = None


class InventoryItemUpdate(BaseModel):
    category: Optional[ItemCategory] = None
    name: Optional[str] = Field(None, min_length=1, max_length=150)
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    unit: Optional[ItemUnit] = None
    min_stock: Optional[int] = Field(None, ge=0)
    specs: Optional[Dict[str, Any]] = None
    is_active: Optional[bool] = None


class InventoryItemRead(BaseModel):
    id: uuid.UUID
    category: ItemCategory
    name: str
    brand: Optional[str] = None
    model: Optional[str] = None
    unit: ItemUnit
    has_serial: bool
    min_stock: int
    stock_qty: int
    specs: Optional[Dict[str, Any]] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LowStockItemRead(BaseModel):
    id: uuid.UUID
    category: ItemCategory
    name: str
    brand: Optional[str] = None
    model: Optional[str] = None
    unit: ItemUnit
    min_stock: int
    stock_qty: int
    shortage: int


# Stock Movement Schemas
class StockInRequest(BaseModel):
    item_id: uuid.UUID
    qty: int = Field(..., gt=0)
    supplier_id: Optional[uuid.UUID] = None
    unit_cost: Optional[int] = Field(None, ge=0, description="Unit cost in paise")
    invoice_no: Optional[str] = Field(None, max_length=100)
    note: Optional[str] = None
    serial_numbers: Optional[List[str]] = Field(None, description="List of serial numbers for serialized items")
    warranty_months: int = Field(0, ge=0, description="Warranty duration in months for serial items")


class StockOutRequest(BaseModel):
    item_id: uuid.UUID
    qty: int = Field(..., gt=0)
    customer_id: uuid.UUID
    note: Optional[str] = None
    serial_numbers: Optional[List[str]] = Field(None, description="List of serial numbers to issue from stock")


class StockAdjustRequest(BaseModel):
    item_id: uuid.UUID
    new_qty: int = Field(..., ge=0, description="New exact stock quantity")
    note: str = Field(..., min_length=3, description="Mandatory audit explanation for stock adjustment")


class StockMovementRead(BaseModel):
    id: uuid.UUID
    item_id: uuid.UUID
    item_name: Optional[str] = None
    type: StockMovementType
    qty: int
    supplier_id: Optional[uuid.UUID] = None
    supplier_name: Optional[str] = None
    customer_id: Optional[uuid.UUID] = None
    customer_name: Optional[str] = None
    unit_cost: Optional[int] = None
    invoice_no: Optional[str] = None
    note: Optional[str] = None
    moved_by: uuid.UUID
    mover_name: Optional[str] = None
    moved_at: datetime

    model_config = ConfigDict(from_attributes=True)


# Serial Item Schemas
class SerialItemRead(BaseModel):
    id: uuid.UUID
    item_id: uuid.UUID
    item_name: Optional[str] = None
    serial_no: str
    status: SerialStatus
    customer_id: Optional[uuid.UUID] = None
    customer_name: Optional[str] = None
    supplier_id: Optional[uuid.UUID] = None
    supplier_name: Optional[str] = None
    warranty_months: int
    warranty_until: Optional[datetime] = None
    installed_on: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SerialStatusUpdate(BaseModel):
    status: SerialStatus = Field(..., description="New status, e.g. defective or returned")
    note: Optional[str] = None


class SerialDetailRead(BaseModel):
    id: uuid.UUID
    item_id: uuid.UUID
    item_name: str
    category: ItemCategory
    brand: Optional[str] = None
    model: Optional[str] = None
    serial_no: str
    status: SerialStatus
    customer_id: Optional[uuid.UUID] = None
    customer_name: Optional[str] = None
    customer_phone: Optional[str] = None
    customer_address: Optional[str] = None
    supplier_id: Optional[uuid.UUID] = None
    supplier_name: Optional[str] = None
    warranty_months: int
    installed_on: Optional[datetime] = None
    warranty_until: Optional[datetime] = None
    is_under_warranty: bool


# Customer Material Allocations
class CustomerMaterialItemRead(BaseModel):
    item_id: uuid.UUID
    item_name: str
    category: ItemCategory
    unit: ItemUnit
    total_qty: int
    serials: List[SerialItemRead] = []


class CustomerMaterialsResponse(BaseModel):
    customer_id: uuid.UUID
    customer_name: str
    materials: List[CustomerMaterialItemRead]
