import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.enums import LeadStatus, UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_lead_lifecycle_and_conversion(client: AsyncClient, db_session: AsyncSession):
    # Setup Admin and two Sales users
    admin = User(name="Admin", phone="9000000001", role=UserRole.ADMIN, is_active=True)
    sales1 = User(name="Sales 1", phone="9000000002", role=UserRole.SALES, is_active=True)
    sales2 = User(name="Sales 2", phone="9000000003", role=UserRole.SALES, is_active=True)

    db_session.add_all([admin, sales1, sales2])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales1)
    await db_session.refresh(sales2)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    sales1_token = create_access_token(subject=str(sales1.id), role="sales")
    sales2_token = create_access_token(subject=str(sales2.id), role="sales")

    # 1. Sales 1 creates a lead
    create_lead_resp = await client.post(
        "/api/v1/leads",
        headers={"Authorization": f"Bearer {sales1_token}"},
        json={
            "name": "Rohan Sharma",
            "phone": "9811122233",
            "address": "123 Green Avenue, Jaipur",
            "expected_kw": 5.0,
            "source": "Website Form",
            "notes": "Interested in 5kW rooftop system",
        },
    )
    assert create_lead_resp.status_code == 201
    lead_data = create_lead_resp.json()
    lead_id = lead_data["id"]
    assert lead_data["assigned_sales_id"] == str(sales1.id)
    assert lead_data["status"] == "new"

    # 2. Sales 2 tries to view Sales 1's lead -> 403 Forbidden
    sales2_get = await client.get(
        f"/api/v1/leads/{lead_id}",
        headers={"Authorization": f"Bearer {sales2_token}"},
    )
    assert sales2_get.status_code == 403

    # 3. Sales 2 list leads -> does not see Sales 1's lead
    sales2_list = await client.get(
        "/api/v1/leads",
        headers={"Authorization": f"Bearer {sales2_token}"},
    )
    assert sales2_list.status_code == 200
    assert sales2_list.json()["total"] == 0

    # 4. Admin can reassign lead to Sales 2
    reassign_resp = await client.post(
        f"/api/v1/leads/{lead_id}/assign",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"assigned_sales_id": str(sales2.id)},
    )
    assert reassign_resp.status_code == 200
    assert reassign_resp.json()["assigned_sales_id"] == str(sales2.id)

    # 5. Sales 2 can now convert the lead
    convert_resp = await client.post(
        f"/api/v1/leads/{lead_id}/convert",
        headers={"Authorization": f"Bearer {sales2_token}"},
        json={
            "address": "123 Green Avenue, Jaipur",
            "latitude": 26.9124,
            "longitude": 75.7873,
            "final_price": 25000000,  # Rs. 2,50,000 in paise
            "capacity_kw": 5.0,
            "phase": "single",
            "panel_brand": "Tata Power Solar",
            "panel_watt": 550,
            "panel_count": 10,
            "inverter_brand": "Growatt",
            "structure_type": "High Rise HDG",
        },
    )
    assert convert_resp.status_code == 200
    customer_data = convert_resp.json()
    assert customer_data["name"] == "Rohan Sharma"
    assert customer_data["mobile"] == "9811122233"
    assert customer_data["stage"] == "SALE_CONFIRMED"
    assert customer_data["sales_id"] == str(sales2.id)

    # 6. Verify lead is marked converted
    lead_check = await client.get(
        f"/api/v1/leads/{lead_id}",
        headers={"Authorization": f"Bearer {sales2_token}"},
    )
    assert lead_check.status_code == 200
    assert lead_check.json()["status"] == "converted"
    assert lead_check.json()["customer_id"] == customer_data["id"]


@pytest.mark.asyncio
async def test_mark_lead_lost(client: AsyncClient, db_session: AsyncSession):
    sales = User(name="Sales Agent", phone="9000000010", role=UserRole.SALES, is_active=True)
    db_session.add(sales)
    await db_session.commit()
    await db_session.refresh(sales)

    sales_token = create_access_token(subject=str(sales.id), role="sales")

    # Create lead
    lead_resp = await client.post(
        "/api/v1/leads",
        headers={"Authorization": f"Bearer {sales_token}"},
        json={"name": "Lost Prospect", "phone": "9988776655"},
    )
    lead_id = lead_resp.json()["id"]

    # Mark lost
    lost_resp = await client.post(
        f"/api/v1/leads/{lead_id}/mark-lost",
        headers={"Authorization": f"Bearer {sales_token}"},
        json={"reason": "Customer went with another competitor offering lower prices."},
    )
    assert lost_resp.status_code == 200
    data = lost_resp.json()
    assert data["status"] == "lost"
    assert "competitor" in data["lost_reason"]
