import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.enums import CustomerStage, UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_customer_scoping_and_stage_transitions(client: AsyncClient, db_session: AsyncSession):
    admin = User(name="Admin", phone="9000000020", role=UserRole.ADMIN, is_active=True)
    sales1 = User(name="Sales A", phone="9000000021", role=UserRole.SALES, is_active=True)
    sales2 = User(name="Sales B", phone="9000000022", role=UserRole.SALES, is_active=True)

    db_session.add_all([admin, sales1, sales2])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales1)
    await db_session.refresh(sales2)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    sales1_token = create_access_token(subject=str(sales1.id), role="sales")
    sales2_token = create_access_token(subject=str(sales2.id), role="sales")

    # 1. Sales 1 creates customer
    create_resp = await client.post(
        "/api/v1/customers",
        headers={"Authorization": f"Bearer {sales1_token}"},
        json={
            "name": "Amit Patel",
            "mobile": "9822233344",
            "address": "45 Solar Colony, Ahmedabad",
            "latitude": 23.0225,
            "longitude": 72.5714,
            "final_price": 18000000,
            "capacity_kw": 3.3,
            "phase": "single",
            "panel_brand": "Adani Solar",
            "panel_watt": 540,
            "panel_count": 6,
            "inverter_brand": "Solis",
            "structure_type": "Tin Shade Elevated",
        },
    )
    assert create_resp.status_code == 201
    cust = create_resp.json()
    cust_id = cust["id"]
    client_user_id = cust["user_id"]

    # 2. Sales 2 cannot view customer -> 403 Forbidden
    s2_get = await client.get(
        f"/api/v1/customers/{cust_id}",
        headers={"Authorization": f"Bearer {sales2_token}"},
    )
    assert s2_get.status_code == 403

    # 3. Client user can view their own record
    client_token = create_access_token(subject=str(client_user_id), role="client")
    client_get = await client.get(
        f"/api/v1/customers/{cust_id}",
        headers={"Authorization": f"Bearer {client_token}"},
    )
    assert client_get.status_code == 200
    assert client_get.json()["name"] == "Amit Patel"

    # 4. Non-admin cannot change stage directly -> 403 Forbidden
    sales_stage_update = await client.patch(
        f"/api/v1/customers/{cust_id}/stage",
        headers={"Authorization": f"Bearer {sales1_token}"},
        json={"stage": "DOCUMENTS_RECEIVED"},
    )
    assert sales_stage_update.status_code == 403

    # 5. Invalid stage transition by Admin (SALE_CONFIRMED to INSTALLATION_COMPLETE) -> 400
    invalid_stage = await client.patch(
        f"/api/v1/customers/{cust_id}/stage",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"stage": "INSTALLATION_COMPLETE"},
    )
    assert invalid_stage.status_code == 400
    assert "Invalid stage transition" in invalid_stage.json()["error"]["message"]

    # 6. Valid stage transition by Admin (SALE_CONFIRMED -> DOCUMENTS_RECEIVED)
    valid_stage = await client.patch(
        f"/api/v1/customers/{cust_id}/stage",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"stage": "DOCUMENTS_RECEIVED", "note": "Physical verification done"},
    )
    assert valid_stage.status_code == 200
    assert valid_stage.json()["stage"] == "DOCUMENTS_RECEIVED"
    assert len(valid_stage.json()["stage_histories"]) >= 2
