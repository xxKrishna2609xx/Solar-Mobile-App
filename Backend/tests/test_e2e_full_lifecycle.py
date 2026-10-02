from datetime import datetime, timezone
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.enums import CustomerPhase, CustomerStage, ItemCategory, TeamType, UserRole, WorkType
from app.models.team import Team
from app.models.user import User


@pytest.mark.asyncio
async def test_e2e_solar_project_full_lifecycle(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_headers: dict,
    admin_user: User,
    sample_sales_user: User,
):
    # Setup Sales Auth Headers
    sales_token = create_access_token(str(sample_sales_user.id), sample_sales_user.role.value)
    sales_headers = {"Authorization": f"Bearer {sales_token}"}

    # Setup Structure Team
    structure_team = Team(name="Alpha Structure Team", type=TeamType.STRUCTURE, is_active=True)
    db_session.add(structure_team)
    await db_session.commit()

    # -------------------------------------------------------------
    # 1. Lead Creation & Conversion
    # -------------------------------------------------------------
    lead_res = await client.post(
        "/api/v1/leads",
        json={
            "name": "Kamlesh Verma",
            "phone": "9829123456",
            "address": "Borkhera, Kota",
            "monthly_bill": 450000,
            "source": "referral",
        },
        headers=sales_headers,
    )
    assert lead_res.status_code == 201
    lead_id = lead_res.json()["id"]

    # Convert Lead to Customer
    conv_res = await client.post(
        f"/api/v1/leads/{lead_id}/convert",
        json={
            "capacity_kw": 4.0,
            "final_price": 20000000,  # Rs 2,00,000
            "phase": "single",
            "panel_brand": "Tata Power Solar",
            "inverter_brand": "Havells",
            "structure_type": "Elevated GI",
        },
        headers=sales_headers,
    )
    assert conv_res.status_code == 200
    customer_id = conv_res.json()["id"]
    customer_user_id = conv_res.json()["user_id"]
    assert conv_res.json()["stage"] == "sale_confirmed"

    # Setup Client Auth Headers
    client_token = create_access_token(str(customer_user_id), UserRole.CLIENT.value)
    client_headers = {"Authorization": f"Bearer {client_token}"}

    # -------------------------------------------------------------
    # 2. Document Upload -> Auto Advance to DOCUMENTS_RECEIVED
    # -------------------------------------------------------------
    doc_res = await client.post(
        f"/api/v1/customers/{customer_id}/documents",
        data={"doc_type": "aadhaar"},
        files={"file": ("aadhaar.pdf", b"%PDF-1.4 dummy document content", "application/pdf")},
        headers=sales_headers,
    )
    assert doc_res.status_code == 201

    # Check Customer stage updated
    cust_check1 = await client.get(f"/api/v1/customers/{customer_id}", headers=sales_headers)
    assert cust_check1.json()["stage"] == "documents_received"

    # -------------------------------------------------------------
    # 3. Advance Payment -> Auto Advance to ADVANCE_VERIFIED
    # -------------------------------------------------------------
    pay_res = await client.post(
        f"/api/v1/customers/{customer_id}/payments",
        data={
            "amount": 4000000,  # Rs 40,000 (20% advance)
            "mode": "upi",
            "reference_no": "UPI-TRANS-98765",
            "direct_verify": "true",
        },
        headers=auth_headers,
    )
    assert pay_res.status_code == 201

    # Check Customer stage updated
    cust_check2 = await client.get(f"/api/v1/customers/{customer_id}", headers=sales_headers)
    assert cust_check2.json()["stage"] == "advance_verified"

    # -------------------------------------------------------------
    # 4. Work Assignment & Completion -> INSTALLATION_COMPLETE
    # -------------------------------------------------------------
    work_res = await client.post(
        "/api/v1/work-assignments",
        json={
            "customer_id": customer_id,
            "team_id": str(structure_team.id),
            "work_type": "structure",
            "scheduled_start": datetime.now(timezone.utc).isoformat(),
            "scheduled_end": datetime.now(timezone.utc).isoformat(),
        },
        headers=auth_headers,
    )
    assert work_res.status_code == 201
    work_id = work_res.json()["id"]

    # Start work
    await client.post(
        f"/api/v1/work-assignments/{work_id}/status",
        json={"status": "in_progress", "note": "Structure installation started on site"},
        headers=auth_headers,
    )

    # Upload Photo Proof
    await client.post(
        f"/api/v1/work-assignments/{work_id}/photos",
        files={"file": ("structure_done.jpg", b"\xff\xd8\xff dummy image bytes", "image/jpeg")},
        headers=auth_headers,
    )

    # Complete Work
    await client.post(
        f"/api/v1/work-assignments/{work_id}/status",
        json={"status": "completed", "note": "Structure assembled and torqued"},
        headers=auth_headers,
    )

    # Verify stage auto-advanced to installation_complete
    cust_check3 = await client.get(f"/api/v1/customers/{customer_id}", headers=sales_headers)
    assert cust_check3.json()["stage"] == "installation_complete"

    # -------------------------------------------------------------
    # 5. KEDL Discom Paperwork -> Net Approval -> SYSTEM_LIVE
    # -------------------------------------------------------------
    init_kedl = await client.post(
        f"/api/v1/customers/{customer_id}/kedl-files/init",
        headers=auth_headers,
    )
    assert init_kedl.status_code == 201
    kedl_files = init_kedl.json()
    net_file = next(f for f in kedl_files if f["file_type"] == "net")

    # Approve Net File
    await client.post(
        f"/api/v1/kedl-files/{net_file['id']}/status",
        json={"status": "approved", "note": "Net meter installed and grid sync successful"},
        headers=auth_headers,
    )

    # Verify stage is now SYSTEM_LIVE
    cust_check4 = await client.get(f"/api/v1/customers/{customer_id}", headers=sales_headers)
    assert cust_check4.json()["stage"] == "system_live"

    # -------------------------------------------------------------
    # 6. Client Home Screen & Service Ticket Workflow
    # -------------------------------------------------------------
    home_res = await client.get("/api/v1/client/home", headers=client_headers)
    assert home_res.status_code == 200
    home_data = home_res.json()
    assert home_data["stage"] == "system_live"
    assert len(home_data["timeline"]) == 10

    # Client raises an Inverter Service Ticket
    tck_res = await client.post(
        "/api/v1/client/tickets",
        json={
            "type": "inverter",
            "title": "Grid frequency fluctuation alarm",
            "description": "Alarm beep on inverter display.",
            "error_code": "F-02",
        },
        headers=client_headers,
    )
    assert tck_res.status_code == 201
    ticket_id = tck_res.json()["id"]

    # Technician resolves ticket
    res_tck = await client.post(
        f"/api/v1/tickets/{ticket_id}/status",
        json={
            "status": "resolved",
            "resolution_note": "Re-calibrated grid parameters.",
        },
        headers=auth_headers,
    )
    assert res_tck.status_code == 200
    assert res_tck.json()["status"] == "resolved"

    # -------------------------------------------------------------
    # 7. Material Inventory Stock-out & Warranty Tracking
    # -------------------------------------------------------------
    inv_item_res = await client.post(
        "/api/v1/inventory/items",
        json={
            "category": "inverter",
            "name": "Havells Enviro 4kW",
            "brand": "Havells",
            "unit": "pcs",
            "has_serial": True,
            "min_stock": 1,
        },
        headers=auth_headers,
    )
    item_id = inv_item_res.json()["id"]

    # Stock-in
    await client.post(
        "/api/v1/inventory/stock-in",
        json={
            "item_id": item_id,
            "qty": 1,
            "serial_numbers": ["HV-4KW-00100"],
            "warranty_months": 60,
        },
        headers=auth_headers,
    )

    # Stock-out to customer
    await client.post(
        "/api/v1/inventory/stock-out",
        json={
            "item_id": item_id,
            "qty": 1,
            "customer_id": customer_id,
            "serial_numbers": ["HV-4KW-00100"],
        },
        headers=auth_headers,
    )

    # Verify reverse serial warranty lookup
    serial_lookup = await client.get("/api/v1/serials/HV-4KW-00100", headers=auth_headers)
    assert serial_lookup.status_code == 200
    assert serial_lookup.json()["customer_name"] == "Kamlesh Verma"
    assert serial_lookup.json()["is_under_warranty"] is True
