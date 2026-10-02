from datetime import date, timedelta
from unittest.mock import AsyncMock, patch
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.customer import Customer
from app.models.enums import CustomerStage, SystemPhase, UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_kedl_lifecycle_demands_and_system_live(client: AsyncClient, db_session: AsyncSession):
    # Setup Admin, two KEDL employees, Sales, Client
    admin = User(name="Admin", phone="9000000070", role=UserRole.ADMIN, is_active=True)
    kedl1 = User(name="KEDL Agent 1", phone="9000000071", role=UserRole.KEDL, is_active=True)
    kedl2 = User(name="KEDL Agent 2", phone="9000000072", role=UserRole.KEDL, is_active=True)
    sales = User(name="Sales", phone="9000000073", role=UserRole.SALES, is_active=True)
    client_user = User(name="Client", phone="9000000074", role=UserRole.CLIENT, is_active=True)

    db_session.add_all([admin, kedl1, kedl2, sales, client_user])
    await db_session.commit()
    for u in [admin, kedl1, kedl2, sales, client_user]:
        await db_session.refresh(u)

    # Customer in INSTALLATION_COMPLETE stage
    customer = Customer(
        name="Pooja Mehta",
        mobile="9000000074",
        address="55 Residency Road, Udaipur",
        sales_id=sales.id,
        user_id=client_user.id,
        final_price=22000000,
        capacity_kw=4.5,
        phase=SystemPhase.SINGLE,
        panel_brand="Tata Power",
        panel_watt=550,
        panel_count=9,
        inverter_brand="Growatt",
        structure_type="Standard",
        stage=CustomerStage.INSTALLATION_COMPLETE,
    )
    db_session.add(customer)
    await db_session.commit()
    await db_session.refresh(customer)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    kedl1_token = create_access_token(subject=str(kedl1.id), role="kedl")
    kedl2_token = create_access_token(subject=str(kedl2.id), role="kedl")

    # 1. Admin initializes KEDL files for customer and assigns to KEDL Agent 1
    init_resp = await client.post(
        f"/api/v1/customers/{customer.id}/kedl-files/init",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"assigned_to": str(kedl1.id)},
    )
    assert init_resp.status_code == 201
    files = init_resp.json()
    assert len(files) == 3
    file_types = [f["file_type"] for f in files]
    assert "name_change" in file_types
    assert "load" in file_types
    assert "net" in file_types

    net_file = next(f for f in files if f["file_type"] == "net")
    load_file = next(f for f in files if f["file_type"] == "load")
    net_file_id = net_file["id"]
    load_file_id = load_file["id"]

    # 2. Customer stage should have moved to KEDL_PROCESS
    cust_check = await client.get(
        f"/api/v1/customers/{customer.id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert cust_check.status_code == 200
    assert cust_check.json()["stage"] == "KEDL_PROCESS"

    # 3. Duplicate initialization is blocked (409 Conflict)
    dup_init = await client.post(
        f"/api/v1/customers/{customer.id}/kedl-files/init",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={},
    )
    assert dup_init.status_code == 409

    # 4. KEDL Agent 2 cannot see Agent 1's assigned files -> returns empty list
    k2_list = await client.get(
        "/api/v1/kedl-files",
        headers={"Authorization": f"Bearer {kedl2_token}"},
    )
    assert k2_list.status_code == 200
    assert len(k2_list.json()) == 0

    # 5. KEDL Agent 1 submits the Load file
    submit_load = await client.post(
        f"/api/v1/kedl-files/{load_file_id}/status",
        headers={"Authorization": f"Bearer {kedl1_token}"},
        json={"status": "submitted", "note": "Application submitted at KEDL circle office"},
    )
    assert submit_load.status_code == 200
    assert submit_load.json()["status"] == "submitted"

    # 6. KEDL raises a demand on the Load file (e.g. load extension fee)
    demand_resp = await client.post(
        f"/api/v1/kedl-files/{load_file_id}/demands",
        headers={"Authorization": f"Bearer {kedl1_token}"},
        json={
            "description": "Additional security deposit and load enhancement fee",
            "amount": 250000,  # Rs. 2,500
            "due_date": str(date.today() + timedelta(days=7)),
        },
    )
    assert demand_resp.status_code == 201
    demand = demand_resp.json()
    demand_id = demand["id"]
    assert demand["status"] == "open"

    # File status should have auto-transitioned to demand_raised
    load_check = await client.get(
        f"/api/v1/kedl-files/{load_file_id}",
        headers={"Authorization": f"Bearer {kedl1_token}"},
    )
    assert load_check.json()["status"] == "demand_raised"

    # 7. Resolve the demand (mark paid with receipt)
    with patch("app.services.kedl_service.storage_service.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.kedl_service.storage_service.get_presigned_url", new_callable=AsyncMock) as mock_url:

        mock_upload.return_value = "mock_receipt_key"
        mock_url.return_value = "https://minio.local/presigned-receipt.pdf"

        pay_demand = await client.patch(
            f"/api/v1/kedl-demands/{demand_id}",
            headers={"Authorization": f"Bearer {kedl1_token}"},
            data={"status": "paid"},
            files={"receipt_file": ("challan.pdf", b"%PDF-1.4 dummy", "application/pdf")},
        )
        assert pay_demand.status_code == 200
        assert pay_demand.json()["status"] == "paid"

        # Load file status should have auto-transitioned to demand_paid
        load_paid_check = await client.get(
            f"/api/v1/kedl-files/{load_file_id}",
            headers={"Authorization": f"Bearer {kedl1_token}"},
        )
        assert load_paid_check.json()["status"] == "demand_paid"

    # 8. KEDL Agent 1 submits Net file and then gets it APPROVED
    await client.post(
        f"/api/v1/kedl-files/{net_file_id}/status",
        headers={"Authorization": f"Bearer {kedl1_token}"},
        json={"status": "submitted"},
    )
    approve_net = await client.post(
        f"/api/v1/kedl-files/{net_file_id}/status",
        headers={"Authorization": f"Bearer {kedl1_token}"},
        json={"status": "approved", "note": "Net meter installed and test report accepted"},
    )
    assert approve_net.status_code == 200
    assert approve_net.json()["status"] == "approved"

    # 9. Customer stage should have auto-progressed to SYSTEM_LIVE
    cust_live = await client.get(
        f"/api/v1/customers/{customer.id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert cust_live.status_code == 200
    assert cust_live.json()["stage"] == "SYSTEM_LIVE"

    # 10. Dashboard metrics check
    dash_resp = await client.get(
        "/api/v1/kedl/dashboard",
        headers={"Authorization": f"Bearer {kedl1_token}"},
    )
    assert dash_resp.status_code == 200
    dash_data = dash_resp.json()
    assert dash_data["total_files"] == 3
    assert dash_data["open_demands_count"] == 0
