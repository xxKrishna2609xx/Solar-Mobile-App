from typing import List, Optional
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import ItemCategory, StockMovementType, UserRole
from app.models.user import User
from app.schemas.inventory import (
    CustomerMaterialsResponse,
    InventoryItemCreate,
    InventoryItemRead,
    InventoryItemUpdate,
    LowStockItemRead,
    SerialDetailRead,
    SerialItemRead,
    SerialStatusUpdate,
    StockAdjustRequest,
    StockInRequest,
    StockMovementRead,
    StockOutRequest,
    SupplierCreate,
    SupplierRead,
    SupplierUpdate,
)
from app.services.inventory_service import InventoryService

router = APIRouter(tags=["Inventory & Materials"])


# ------------------ SUPPLIERS ------------------
@router.get(
    "/suppliers",
    response_model=List[SupplierRead],
    summary="List suppliers",
)
async def list_suppliers(
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.list_suppliers(db, is_active=is_active, limit=limit, offset=offset)


@router.post(
    "/suppliers",
    response_model=SupplierRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new supplier (Admin, Manager)",
)
async def create_supplier(
    data: SupplierCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await InventoryService.create_supplier(db, data)


@router.get(
    "/suppliers/{supplier_id}",
    response_model=SupplierRead,
    summary="Get supplier details",
)
async def get_supplier(
    supplier_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.get_supplier(db, supplier_id)


@router.patch(
    "/suppliers/{supplier_id}",
    response_model=SupplierRead,
    summary="Update supplier details (Admin, Manager)",
)
async def update_supplier(
    supplier_id: uuid.UUID,
    data: SupplierUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await InventoryService.update_supplier(db, supplier_id, data)


@router.delete(
    "/suppliers/{supplier_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a supplier (Admin)",
)
async def delete_supplier(
    supplier_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    await InventoryService.delete_supplier(db, supplier_id)


# ------------------ INVENTORY ITEMS ------------------
@router.get(
    "/inventory/items",
    response_model=List[InventoryItemRead],
    summary="List inventory items with search and category filters",
)
async def list_items(
    category: Optional[ItemCategory] = Query(None, description="Filter by category"),
    low_stock: bool = Query(False, description="Filter items at or below minimum stock"),
    search: Optional[str] = Query(None, description="Search query in name/brand/model"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.list_items(
        db,
        category=category,
        low_stock=low_stock,
        search=search,
        is_active=is_active,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/inventory/low-stock",
    response_model=List[LowStockItemRead],
    summary="Get all items running below minimum stock threshold",
)
async def get_low_stock_items(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.get_low_stock_items(db)


@router.post(
    "/inventory/items",
    response_model=InventoryItemRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new inventory material item (Admin, Manager)",
)
async def create_item(
    data: InventoryItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await InventoryService.create_item(db, data)


@router.get(
    "/inventory/items/{item_id}",
    response_model=InventoryItemRead,
    summary="Get inventory item details",
)
async def get_item(
    item_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.get_item(db, item_id)


@router.patch(
    "/inventory/items/{item_id}",
    response_model=InventoryItemRead,
    summary="Update inventory item details (Admin, Manager)",
)
async def update_item(
    item_id: uuid.UUID,
    data: InventoryItemUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await InventoryService.update_item(db, item_id, data)


@router.delete(
    "/inventory/items/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an inventory item (Admin)",
)
async def delete_item(
    item_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    await InventoryService.delete_item(db, item_id)


# ------------------ STOCK MOVEMENTS ------------------
@router.post(
    "/inventory/stock-in",
    response_model=StockMovementRead,
    status_code=status.HTTP_201_CREATED,
    summary="Record incoming stock from supplier with serial numbers (Staff)",
)
async def stock_in(
    data: StockInRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.OFFICE_STAFF)
    ),
):
    movement = await InventoryService.stock_in(db, data, current_user)
    return InventoryService.build_movement_read(movement)


@router.post(
    "/inventory/stock-out",
    response_model=StockMovementRead,
    status_code=status.HTTP_201_CREATED,
    summary="Issue stock and serial numbers to a customer project (Staff, Technicians)",
)
async def stock_out(
    data: StockOutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.OFFICE_STAFF, UserRole.TECHNICIAN)
    ),
):
    movement = await InventoryService.stock_out(db, data, current_user)
    return InventoryService.build_movement_read(movement)


@router.post(
    "/inventory/adjust",
    response_model=StockMovementRead,
    summary="Manually adjust inventory count with mandatory audit note (Admin, Manager)",
)
async def adjust_stock(
    data: StockAdjustRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    movement = await InventoryService.adjust_stock(db, data, current_user)
    return InventoryService.build_movement_read(movement)


@router.get(
    "/inventory/movements",
    response_model=List[StockMovementRead],
    summary="List stock ledger movements with filters",
)
async def list_movements(
    item_id: Optional[uuid.UUID] = Query(None, description="Filter by item ID"),
    customer_id: Optional[uuid.UUID] = Query(None, description="Filter by customer ID"),
    supplier_id: Optional[uuid.UUID] = Query(None, description="Filter by supplier ID"),
    movement_type: Optional[StockMovementType] = Query(None, alias="type", description="Filter by movement type"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    movements = await InventoryService.list_movements(
        db,
        item_id=item_id,
        customer_id=customer_id,
        supplier_id=supplier_id,
        movement_type=movement_type,
        limit=limit,
        offset=offset,
    )
    return [InventoryService.build_movement_read(m) for m in movements]


# ------------------ CUSTOMER MATERIALS & SERIALS ------------------
@router.get(
    "/customers/{customer_id}/materials",
    response_model=CustomerMaterialsResponse,
    summary="List all solar materials and serial numbers issued to a customer project",
)
async def get_customer_materials(
    customer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.get_customer_materials(db, customer_id)


@router.get(
    "/serials/{serial_no}",
    response_model=SerialDetailRead,
    summary="Reverse lookup a panel or inverter serial number for project and warranty details",
)
async def get_serial_details(
    serial_no: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await InventoryService.get_serial_detail(db, serial_no)


@router.patch(
    "/serials/{serial_id}/status",
    response_model=SerialItemRead,
    summary="Update status of a serial item (defective/returned)",
)
async def update_serial_status(
    serial_id: uuid.UUID,
    data: SerialStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.TECHNICIAN)
    ),
):
    serial = await InventoryService.update_serial_status(db, serial_id, data, current_user)
    return SerialItemRead(
        id=serial.id,
        item_id=serial.item_id,
        item_name=serial.item.name if serial.item else None,
        serial_no=serial.serial_no,
        status=serial.status,
        customer_id=serial.customer_id,
        customer_name=serial.customer.name if serial.customer else None,
        supplier_id=serial.supplier_id,
        supplier_name=serial.supplier.name if serial.supplier else None,
        warranty_months=serial.warranty_months,
        warranty_until=serial.warranty_until,
        installed_on=serial.installed_on,
        created_at=serial.created_at,
    )
