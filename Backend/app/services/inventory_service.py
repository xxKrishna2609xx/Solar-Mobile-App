from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import ConflictException, NotFoundException, ValidationException
from app.models.customer import Customer
from app.models.enums import ItemCategory, ItemUnit, SerialStatus, StockMovementType
from app.models.inventory import InventoryItem, PlannedMaterial, SerialItem, StockMovement, Supplier
from app.models.user import User
from app.schemas.inventory import (
    CustomerMaterialItemRead,
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


class InventoryService:
    # ------------------ SUPPLIER METHODS ------------------
    @staticmethod
    async def create_supplier(db: AsyncSession, data: SupplierCreate) -> Supplier:
        supplier = Supplier(
            name=data.name,
            phone=data.phone,
            address=data.address,
            gst_no=data.gst_no,
        )
        db.add(supplier)
        await db.commit()
        await db.refresh(supplier)
        return supplier

    @staticmethod
    async def get_supplier(db: AsyncSession, supplier_id: uuid.UUID) -> Supplier:
        stmt = select(Supplier).where(Supplier.id == supplier_id, Supplier.is_deleted == False)  # noqa: E712
        supplier = (await db.execute(stmt)).scalar_one_or_none()
        if not supplier:
            raise NotFoundException("Supplier not found.")
        return supplier

    @staticmethod
    async def list_suppliers(
        db: AsyncSession,
        is_active: Optional[bool] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Supplier]:
        stmt = (
            select(Supplier)
            .where(Supplier.is_deleted == False)  # noqa: E712
            .order_by(Supplier.name.asc())
            .offset(offset)
            .limit(limit)
        )
        if is_active is not None:
            stmt = stmt.where(Supplier.is_active == is_active)
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def update_supplier(
        db: AsyncSession, supplier_id: uuid.UUID, data: SupplierUpdate
    ) -> Supplier:
        supplier = await InventoryService.get_supplier(db, supplier_id)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(supplier, key, value)
        await db.commit()
        await db.refresh(supplier)
        return supplier

    @staticmethod
    async def delete_supplier(db: AsyncSession, supplier_id: uuid.UUID) -> None:
        supplier = await InventoryService.get_supplier(db, supplier_id)
        supplier.is_deleted = True
        await db.commit()

    # ------------------ ITEM METHODS ------------------
    @staticmethod
    async def create_item(db: AsyncSession, data: InventoryItemCreate) -> InventoryItem:
        item = InventoryItem(
            category=data.category,
            name=data.name,
            brand=data.brand,
            model=data.model,
            unit=data.unit,
            has_serial=data.has_serial,
            min_stock=data.min_stock,
            stock_qty=0,
            specs=data.specs,
        )
        db.add(item)
        await db.commit()
        await db.refresh(item)
        return item

    @staticmethod
    async def get_item(db: AsyncSession, item_id: uuid.UUID) -> InventoryItem:
        stmt = select(InventoryItem).where(
            InventoryItem.id == item_id,
            InventoryItem.is_deleted == False,  # noqa: E712
        )
        item = (await db.execute(stmt)).scalar_one_or_none()
        if not item:
            raise NotFoundException("Inventory item not found.")
        return item

    @staticmethod
    async def list_items(
        db: AsyncSession,
        category: Optional[ItemCategory] = None,
        low_stock: bool = False,
        search: Optional[str] = None,
        is_active: Optional[bool] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[InventoryItem]:
        stmt = (
            select(InventoryItem)
            .where(InventoryItem.is_deleted == False)  # noqa: E712
            .order_by(InventoryItem.name.asc())
            .offset(offset)
            .limit(limit)
        )
        if category:
            stmt = stmt.where(InventoryItem.category == category)
        if is_active is not None:
            stmt = stmt.where(InventoryItem.is_active == is_active)
        if low_stock:
            stmt = stmt.where(InventoryItem.stock_qty <= InventoryItem.min_stock)
        if search:
            pattern = f"%{search}%"
            stmt = stmt.where(
                or_(
                    InventoryItem.name.ilike(pattern),
                    InventoryItem.brand.ilike(pattern),
                    InventoryItem.model.ilike(pattern),
                )
            )
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def get_low_stock_items(db: AsyncSession) -> List[LowStockItemRead]:
        stmt = (
            select(InventoryItem)
            .where(
                InventoryItem.is_deleted == False,  # noqa: E712
                InventoryItem.is_active == True,  # noqa: E712
                InventoryItem.stock_qty <= InventoryItem.min_stock,
            )
            .order_by((InventoryItem.min_stock - InventoryItem.stock_qty).desc())
        )
        result = await db.execute(stmt)
        items = result.scalars().all()
        return [
            LowStockItemRead(
                id=i.id,
                category=i.category,
                name=i.name,
                brand=i.brand,
                model=i.model,
                unit=i.unit,
                min_stock=i.min_stock,
                stock_qty=i.stock_qty,
                shortage=max(0, i.min_stock - i.stock_qty),
            )
            for i in items
        ]

    @staticmethod
    async def update_item(
        db: AsyncSession, item_id: uuid.UUID, data: InventoryItemUpdate
    ) -> InventoryItem:
        item = await InventoryService.get_item(db, item_id)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(item, key, value)
        await db.commit()
        await db.refresh(item)
        return item

    @staticmethod
    async def delete_item(db: AsyncSession, item_id: uuid.UUID) -> None:
        item = await InventoryService.get_item(db, item_id)
        item.is_deleted = True
        await db.commit()

    # ------------------ STOCK MOVEMENTS ------------------
    @staticmethod
    async def stock_in(
        db: AsyncSession, data: StockInRequest, user: User
    ) -> StockMovement:
        # Lock item row
        stmt = (
            select(InventoryItem)
            .where(InventoryItem.id == data.item_id, InventoryItem.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        item = (await db.execute(stmt)).scalar_one_or_none()
        if not item:
            raise NotFoundException("Inventory item not found.")

        if data.supplier_id:
            await InventoryService.get_supplier(db, data.supplier_id)

        # Validate serial numbers for serialized items
        if item.has_serial:
            serials = data.serial_numbers or []
            if len(serials) != data.qty:
                raise ValidationException(
                    f"Item '{item.name}' requires exactly {data.qty} serial numbers, received {len(serials)}."
                )

            # Check for duplicate serials within this request
            if len(set(serials)) != len(serials):
                raise ValidationException("Duplicate serial numbers detected in request.")

            # Check if any serial number already exists for this item
            dup_stmt = select(SerialItem.serial_no).where(
                SerialItem.item_id == item.id,
                SerialItem.serial_no.in_(serials),
            )
            existing_serials = list((await db.execute(dup_stmt)).scalars().all())
            if existing_serials:
                raise ConflictException(
                    f"Serial number(s) already exist for this item: {', '.join(existing_serials)}"
                )

            # Insert serial items
            for s_no in serials:
                serial_obj = SerialItem(
                    item_id=item.id,
                    serial_no=s_no.strip(),
                    status=SerialStatus.IN_STOCK,
                    supplier_id=data.supplier_id,
                    warranty_months=data.warranty_months,
                )
                db.add(serial_obj)

        # Update stock quantity
        item.stock_qty += data.qty

        movement = StockMovement(
            item_id=item.id,
            type=StockMovementType.IN,
            qty=data.qty,
            supplier_id=data.supplier_id,
            unit_cost=data.unit_cost,
            invoice_no=data.invoice_no,
            note=data.note,
            moved_by=user.id,
        )
        db.add(movement)
        await db.commit()
        await db.refresh(movement)
        return movement

    @staticmethod
    async def stock_out(
        db: AsyncSession, data: StockOutRequest, user: User
    ) -> StockMovement:
        # Lock item row
        stmt = (
            select(InventoryItem)
            .where(InventoryItem.id == data.item_id, InventoryItem.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        item = (await db.execute(stmt)).scalar_one_or_none()
        if not item:
            raise NotFoundException("Inventory item not found.")

        # Validate customer
        cust_stmt = select(Customer).where(Customer.id == data.customer_id, Customer.is_deleted == False)  # noqa: E712
        customer = (await db.execute(cust_stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        # Check stock quantity
        if item.stock_qty < data.qty:
            raise ValidationException(
                f"Insufficient stock for '{item.name}'. Available: {item.stock_qty}, Requested: {data.qty}"
            )

        # Handle serialized items
        if item.has_serial:
            serials = data.serial_numbers or []
            if len(serials) != data.qty:
                raise ValidationException(
                    f"Item '{item.name}' requires selecting exactly {data.qty} serial numbers from stock, received {len(serials)}."
                )

            # Fetch requested serials with lock
            serials_stmt = (
                select(SerialItem)
                .where(
                    SerialItem.item_id == item.id,
                    SerialItem.serial_no.in_(serials),
                    SerialItem.status == SerialStatus.IN_STOCK,
                )
                .with_for_update()
            )
            available_serials = list((await db.execute(serials_stmt)).scalars().all())
            if len(available_serials) != data.qty:
                found_serials = {s.serial_no for s in available_serials}
                missing = [s for s in serials if s not in found_serials]
                raise ValidationException(
                    f"The following serial numbers are not available in stock: {', '.join(missing)}"
                )

            # Mark serials as installed and calculate warranty
            now = datetime.now(timezone.utc)
            for s in available_serials:
                s.status = SerialStatus.INSTALLED
                s.customer_id = customer.id
                s.installed_on = now
                if s.warranty_months > 0:
                    s.warranty_until = now + timedelta(days=s.warranty_months * 30)

        # Decrease stock quantity
        item.stock_qty -= data.qty

        movement = StockMovement(
            item_id=item.id,
            type=StockMovementType.OUT,
            qty=data.qty,
            customer_id=customer.id,
            note=data.note,
            moved_by=user.id,
        )
        db.add(movement)
        await db.commit()
        await db.refresh(movement)
        return movement

    @staticmethod
    async def adjust_stock(
        db: AsyncSession, data: StockAdjustRequest, user: User
    ) -> StockMovement:
        stmt = (
            select(InventoryItem)
            .where(InventoryItem.id == data.item_id, InventoryItem.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        item = (await db.execute(stmt)).scalar_one_or_none()
        if not item:
            raise NotFoundException("Inventory item not found.")

        old_qty = item.stock_qty
        delta = data.new_qty - old_qty
        item.stock_qty = data.new_qty

        movement = StockMovement(
            item_id=item.id,
            type=StockMovementType.ADJUST,
            qty=delta,
            note=f"Adjustment from {old_qty} to {data.new_qty}: {data.note}",
            moved_by=user.id,
        )
        db.add(movement)
        await db.commit()
        await db.refresh(movement)
        return movement

    @staticmethod
    async def list_movements(
        db: AsyncSession,
        item_id: Optional[uuid.UUID] = None,
        customer_id: Optional[uuid.UUID] = None,
        supplier_id: Optional[uuid.UUID] = None,
        movement_type: Optional[StockMovementType] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[StockMovement]:
        stmt = (
            select(StockMovement)
            .options(
                selectinload(StockMovement.item),
                selectinload(StockMovement.supplier),
                selectinload(StockMovement.customer),
                selectinload(StockMovement.mover),
            )
            .order_by(StockMovement.moved_at.desc())
            .offset(offset)
            .limit(limit)
        )
        if item_id:
            stmt = stmt.where(StockMovement.item_id == item_id)
        if customer_id:
            stmt = stmt.where(StockMovement.customer_id == customer_id)
        if supplier_id:
            stmt = stmt.where(StockMovement.supplier_id == supplier_id)
        if movement_type:
            stmt = stmt.where(StockMovement.type == movement_type)

        result = await db.execute(stmt)
        return list(result.scalars().all())

    # ------------------ CUSTOMER PROJECT MATERIALS ------------------
    @staticmethod
    async def get_customer_materials(
        db: AsyncSession, customer_id: uuid.UUID
    ) -> CustomerMaterialsResponse:
        cust_stmt = select(Customer).where(Customer.id == customer_id, Customer.is_deleted == False)  # noqa: E712
        customer = (await db.execute(cust_stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        # Query all stock out movements for this customer
        stmt = (
            select(StockMovement)
            .options(selectinload(StockMovement.item))
            .where(
                StockMovement.customer_id == customer_id,
                StockMovement.type == StockMovementType.OUT,
            )
        )
        movements = list((await db.execute(stmt)).scalars().all())

        # Query all serial items installed for this customer
        serial_stmt = (
            select(SerialItem)
            .options(selectinload(SerialItem.item), selectinload(SerialItem.supplier))
            .where(SerialItem.customer_id == customer_id)
        )
        serials = list((await db.execute(serial_stmt)).scalars().all())

        # Group serials by item_id
        serials_by_item: Dict[uuid.UUID, List[SerialItem]] = {}
        for s in serials:
            serials_by_item.setdefault(s.item_id, []).append(s)

        # Group movements by item_id
        items_map: Dict[uuid.UUID, Dict[str, Any]] = {}
        for m in movements:
            if m.item_id not in items_map:
                items_map[m.item_id] = {
                    "item": m.item,
                    "total_qty": 0,
                }
            items_map[m.item_id]["total_qty"] += m.qty

        material_items: List[CustomerMaterialItemRead] = []
        for item_id, data in items_map.items():
            item = data["item"]
            item_serials = serials_by_item.get(item_id, [])
            serials_read = [
                SerialItemRead(
                    id=s.id,
                    item_id=s.item_id,
                    item_name=item.name,
                    serial_no=s.serial_no,
                    status=s.status,
                    customer_id=s.customer_id,
                    customer_name=customer.name,
                    supplier_id=s.supplier_id,
                    supplier_name=s.supplier.name if s.supplier else None,
                    warranty_months=s.warranty_months,
                    warranty_until=s.warranty_until,
                    installed_on=s.installed_on,
                    created_at=s.created_at,
                )
                for s in item_serials
            ]
            material_items.append(
                CustomerMaterialItemRead(
                    item_id=item.id,
                    item_name=item.name,
                    category=item.category,
                    unit=item.unit,
                    total_qty=data["total_qty"],
                    serials=serials_read,
                )
            )

        return CustomerMaterialsResponse(
            customer_id=customer.id,
            customer_name=customer.name,
            materials=material_items,
        )

    # ------------------ SERIAL LOOKUPS & WARRANTY ------------------
    @staticmethod
    async def get_serial_detail(db: AsyncSession, serial_no: str) -> SerialDetailRead:
        stmt = (
            select(SerialItem)
            .options(
                selectinload(SerialItem.item),
                selectinload(SerialItem.customer),
                selectinload(SerialItem.supplier),
            )
            .where(SerialItem.serial_no == serial_no.strip())
        )
        serial = (await db.execute(stmt)).scalar_one_or_none()
        if not serial:
            raise NotFoundException(f"Serial number '{serial_no}' not found.")

        now = datetime.now(timezone.utc)
        is_under_warranty = False
        if serial.warranty_until:
            warranty_tz = serial.warranty_until if serial.warranty_until.tzinfo else serial.warranty_until.replace(tzinfo=timezone.utc)
            is_under_warranty = warranty_tz >= now

        return SerialDetailRead(
            id=serial.id,
            item_id=serial.item_id,
            item_name=serial.item.name,
            category=serial.item.category,
            brand=serial.item.brand,
            model=serial.item.model,
            serial_no=serial.serial_no,
            status=serial.status,
            customer_id=serial.customer_id,
            customer_name=serial.customer.name if serial.customer else None,
            customer_phone=serial.customer.phone if serial.customer else None,
            customer_address=serial.customer.address if serial.customer else None,
            supplier_id=serial.supplier_id,
            supplier_name=serial.supplier.name if serial.supplier else None,
            warranty_months=serial.warranty_months,
            installed_on=serial.installed_on,
            warranty_until=serial.warranty_until,
            is_under_warranty=is_under_warranty,
        )

    @staticmethod
    async def update_serial_status(
        db: AsyncSession, serial_id: uuid.UUID, data: SerialStatusUpdate, user: User
    ) -> SerialItem:
        stmt = (
            select(SerialItem)
            .options(selectinload(SerialItem.item), selectinload(SerialItem.customer))
            .where(SerialItem.id == serial_id)
        )
        serial = (await db.execute(stmt)).scalar_one_or_none()
        if not serial:
            raise NotFoundException("Serial item not found.")

        old_status = serial.status
        serial.status = data.status

        # If marking defective or returned and it was previously installed, log a note movement if applicable
        if data.status in [SerialStatus.DEFECTIVE, SerialStatus.RETURNED] and old_status == SerialStatus.INSTALLED:
            movement = StockMovement(
                item_id=serial.item_id,
                type=StockMovementType.RETURN if data.status == SerialStatus.RETURNED else StockMovementType.ADJUST,
                qty=0,
                customer_id=serial.customer_id,
                note=f"Serial {serial.serial_no} status changed from {old_status.value} to {data.status.value}: {data.note or 'No reason provided'}",
                moved_by=user.id,
            )
            db.add(movement)

        await db.commit()
        await db.refresh(serial)
        return serial

    @staticmethod
    def build_movement_read(m: StockMovement) -> StockMovementRead:
        return StockMovementRead(
            id=m.id,
            item_id=m.item_id,
            item_name=m.item.name if m.item else None,
            type=m.type,
            qty=m.qty,
            supplier_id=m.supplier_id,
            supplier_name=m.supplier.name if m.supplier else None,
            customer_id=m.customer_id,
            customer_name=m.customer.name if m.customer else None,
            unit_cost=m.unit_cost,
            invoice_no=m.invoice_no,
            note=m.note,
            moved_by=m.moved_by,
            mover_name=m.mover.name if m.mover else None,
            moved_at=m.moved_at,
        )
