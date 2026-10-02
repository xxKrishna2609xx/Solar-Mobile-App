from datetime import datetime, timedelta, timezone
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.customer import Customer
from app.models.enums import CustomerPhase, CustomerStage, ItemCategory, ItemUnit, SerialStatus, UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_supplier_crud(client: AsyncClient, auth_headers: dict):
    # 1. Create Supplier
    create_res = await client.post(
        "/api/v1/suppliers",
        json={
            "name": "Tata Power Solar Distribution",
            "phone": "9829012345",
            "address": "Industrial Area, Kota",
            "gst_no": "08AAAAA0000A1Z5",
        },
        headers=auth_headers,
    )
    assert create_res.status_code == 201
    supplier_id = create_res.json()["id"]
    assert create_res.json()["name"] == "Tata Power Solar Distribution"

    # 2. Get Supplier
    get_res = await client.get(f"/api/v1/suppliers/{supplier_id}", headers=auth_headers)
    assert get_res.status_code == 200
    assert get_res.json()["gst_no"] == "08AAAAA0000A1Z5"

    # 3. Update Supplier
    patch_res = await client.patch(
        f"/api/v1/suppliers/{supplier_id}",
        json={"phone": "9829099999"},
        headers=auth_headers,
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["phone"] == "9829099999"


@pytest.mark.asyncio
async def test_inventory_item_and_low_stock(client: AsyncClient, auth_headers: dict):
    # 1. Create Cable Item with min_stock = 100
    res = await client.post(
        "/api/v1/inventory/items",
        json={
            "category": "cable",
            "name": "DC Solar Cable 4 sq mm",
            "brand": "Polycab",
            "model": "Solar DC 4mm",
            "unit": "meter",
            "has_serial": False,
            "min_stock": 100,
            "specs": {"voltage": "1500V DC", "core": "Copper"},
        },
        headers=auth_headers,
    )
    assert res.status_code == 201
    item_id = res.json()["id"]
    assert res.json()["stock_qty"] == 0

    # 2. Check Low Stock endpoint
    low_res = await client.get("/api/v1/inventory/low-stock", headers=auth_headers)
    assert low_res.status_code == 200
    items = low_res.json()
    item_entry = next((i for i in items if i["id"] == item_id), None)
    assert item_entry is not None
    assert item_entry["shortage"] == 100


@pytest.mark.asyncio
async def test_stock_in_and_serialized_validation(
    client: AsyncClient, db_session: AsyncSession, auth_headers: dict
):
    # 1. Create Inverter Item with has_serial = True
    item_res = await client.post(
        "/api/v1/inventory/items",
        json={
            "category": "inverter",
            "name": "Havells On-Grid Inverter 5kW",
            "brand": "Havells",
            "model": "Enviro GT 5.0",
            "unit": "pcs",
            "has_serial": True,
            "min_stock": 2,
        },
        headers=auth_headers,
    )
    assert item_res.status_code == 201
    item_id = item_res.json()["id"]

    # 2. Stock In with mismatched serial count (qty=2, serials=["INV-001"]) -> should fail
    fail_res = await client.post(
        "/api/v1/inventory/stock-in",
        json={
            "item_id": item_id,
            "qty": 2,
            "serial_numbers": ["INV-001"],
            "warranty_months": 60,
        },
        headers=auth_headers,
    )
    assert fail_res.status_code == 422
    assert "requires exactly 2 serial numbers" in fail_res.text

    # 3. Stock In with valid serial numbers
    success_res = await client.post(
        "/api/v1/inventory/stock-in",
        json={
            "item_id": item_id,
            "qty": 2,
            "serial_numbers": ["INV-001", "INV-002"],
            "warranty_months": 60,
            "unit_cost": 4500000,  # Rs 45,000 in paise
            "invoice_no": "INV-2026-999",
        },
        headers=auth_headers,
    )
    assert success_res.status_code == 201
    assert success_res.json()["type"] == "in"
    assert success_res.json()["qty"] == 2

    # Verify updated stock_qty
    item_check = await client.get(f"/api/v1/inventory/items/{item_id}", headers=auth_headers)
    assert item_check.json()["stock_qty"] == 2


@pytest.mark.asyncio
async def test_stock_out_overselling_and_warranty_tracking(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_headers: dict,
    sample_sales_user: User,
):
    # 1. Setup Customer
    customer = Customer(
        name="Rameshwar Lal",
        phone="9876543299",
        address="Nayapura, Kota",
        capacity_kw=5.0,
        stage=CustomerStage.STRUCTURE_WORK,
        sales_rep_id=sample_sales_user.id,
        final_price=25000000,
    )
    db_session.add(customer)
    await db_session.commit()

    # 2. Create Solar Panel Item
    item_res = await client.post(
        "/api/v1/inventory/items",
        json={
            "category": "panel",
            "name": "Tata Mono Perc 540W",
            "brand": "Tata Power",
            "unit": "pcs",
            "has_serial": True,
            "min_stock": 5,
        },
        headers=auth_headers,
    )
    item_id = item_res.json()["id"]

    # 3. Stock In 2 panels
    await client.post(
        "/api/v1/inventory/stock-in",
        json={
            "item_id": item_id,
            "qty": 2,
            "serial_numbers": ["TP-540-001", "TP-540-002"],
            "warranty_months": 120,  # 10 years
        },
        headers=auth_headers,
    )

    # 4. Try to stock out 3 panels (overselling) -> should fail
    over_res = await client.post(
        "/api/v1/inventory/stock-out",
        json={
            "item_id": item_id,
            "qty": 3,
            "customer_id": str(customer.id),
            "serial_numbers": ["TP-540-001", "TP-540-002", "TP-540-003"],
        },
        headers=auth_headers,
    )
    assert over_res.status_code == 422
    assert "Insufficient stock" in over_res.text

    # 5. Stock out 1 panel to customer
    out_res = await client.post(
        "/api/v1/inventory/stock-out",
        json={
            "item_id": item_id,
            "qty": 1,
            "customer_id": str(customer.id),
            "serial_numbers": ["TP-540-001"],
            "note": "Issued for rooftop structure array",
        },
        headers=auth_headers,
    )
    assert out_res.status_code == 201
    assert out_res.json()["type"] == "out"

    # 6. Verify reverse serial lookup
    serial_res = await client.get("/api/v1/serials/TP-540-001", headers=auth_headers)
    assert serial_res.status_code == 200
    s_data = serial_res.json()
    assert s_data["serial_no"] == "TP-540-001"
    assert s_data["status"] == "installed"
    assert s_data["customer_name"] == "Rameshwar Lal"
    assert s_data["is_under_warranty"] is True
    assert s_data["warranty_until"] is not None

    # 7. Verify Customer Materials view
    mat_res = await client.get(f"/api/v1/customers/{customer.id}/materials", headers=auth_headers)
    assert mat_res.status_code == 200
    mat_data = mat_res.json()
    assert len(mat_data["materials"]) == 1
    assert mat_data["materials"][0]["total_qty"] == 1
    assert mat_data["materials"][0]["serials"][0]["serial_no"] == "TP-540-001"
