from datetime import datetime, timedelta, timezone
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.customer import Customer
from app.models.enums import CustomerPhase, CustomerStage, TicketPriority, TicketStatus, TicketType, UserRole
from app.models.ticket import ServiceTicket
from app.models.user import User


@pytest.mark.asyncio
async def test_client_home_timeline_and_contacts(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_headers: dict,
    sample_sales_user: User,
):
    # 1. Create client user
    client_user = User(
        phone="9876543210",
        name="Sunita Sharma",
        role=UserRole.CLIENT,
        is_active=True,
    )
    db_session.add(client_user)
    await db_session.flush()

    # 2. Create customer linked to client user
    customer = Customer(
        name="Sunita Sharma",
        phone="9876543210",
        address="Sector 14, Kota",
        capacity_kw=5.0,
        stage=CustomerStage.STRUCTURE_WORK,
        sales_rep_id=sample_sales_user.id,
        user_id=client_user.id,
        final_price=25000000,
        phase=CustomerPhase.SINGLE,
        panel_brand="Tata Power Solar",
        panel_watt=540,
        panel_count=10,
        inverter_brand="Havells",
        structure_type="Elevated GI",
    )
    db_session.add(customer)
    await db_session.commit()

    # Get client auth headers
    from app.core.security import create_access_token
    token = create_access_token(str(client_user.id), client_user.role.value)
    client_headers = {"Authorization": f"Bearer {token}"}

    # Fetch Client Home
    response = await client.get("/api/v1/client/home", headers=client_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["customer"]["name"] == "Sunita Sharma"
    assert data["stage"] == "structure_work"
    assert len(data["timeline"]) == 10
    
    # Check timeline status progression
    stages_status = {item["stage"]: item["status"] for item in data["timeline"]}
    assert stages_status["sale_confirmed"] == "done"
    assert stages_status["documents_received"] == "done"
    assert stages_status["advance_verified"] == "done"
    assert stages_status["structure_work"] == "current"
    assert stages_status["electrical_work"] == "upcoming"
    assert stages_status["system_live"] == "upcoming"

    assert data["system_specs"]["capacity_kw"] == 5.0
    assert data["system_specs"]["panel_brand"] == "Tata Power Solar"
    assert data["sales_contact"]["name"] == sample_sales_user.name


@pytest.mark.asyncio
async def test_ticket_creation_and_image_validation(
    client: AsyncClient,
    db_session: AsyncSession,
    sample_sales_user: User,
):
    # Setup client user and live customer
    client_user = User(
        phone="9876543211",
        name="Rajesh Gupta",
        role=UserRole.CLIENT,
        is_active=True,
    )
    db_session.add(client_user)
    await db_session.flush()

    customer = Customer(
        name="Rajesh Gupta",
        phone="9876543211",
        address="Civil Lines, Kota",
        capacity_kw=3.0,
        stage=CustomerStage.SYSTEM_LIVE,
        sales_rep_id=sample_sales_user.id,
        user_id=client_user.id,
        final_price=16000000,
    )
    db_session.add(customer)
    await db_session.commit()

    from app.core.security import create_access_token
    token = create_access_token(str(client_user.id), client_user.role.value)
    headers = {"Authorization": f"Bearer {token}"}

    # Structure ticket with 1 image -> should fail (needs 2-10)
    res = await client.post(
        "/api/v1/client/tickets",
        json={
            "type": "structure",
            "title": "Loose mounting clamp",
            "description": "One clamp seems loose on the south corner.",
            "image_keys": ["tickets/img1.jpg"],
        },
        headers=headers,
    )
    assert res.status_code == 422
    assert "Structure tickets require between 2 and 10 photos" in res.text

    # Structure ticket with 2 images -> succeeds
    res = await client.post(
        "/api/v1/client/tickets",
        json={
            "type": "structure",
            "title": "Loose mounting clamp",
            "description": "One clamp seems loose on the south corner.",
            "image_keys": ["tickets/img1.jpg", "tickets/img2.jpg"],
        },
        headers=headers,
    )
    assert res.status_code == 201
    ticket_data = res.json()
    assert ticket_data["type"] == "structure"
    assert ticket_data["status"] == "open"
    assert ticket_data["ticket_no"].startswith("TCK-")
    assert len(ticket_data["images"]) == 2


@pytest.mark.asyncio
async def test_ticket_lifecycle_and_reopening_window(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_headers: dict,
    sample_sales_user: User,
    admin_user: User,
):
    # Setup client user and live customer
    client_user = User(
        phone="9876543212",
        name="Vikas Meena",
        role=UserRole.CLIENT,
        is_active=True,
    )
    db_session.add(client_user)
    await db_session.flush()

    customer = Customer(
        name="Vikas Meena",
        phone="9876543212",
        address="Talwandi, Kota",
        capacity_kw=4.0,
        stage=CustomerStage.HANDED_OVER,
        sales_rep_id=sample_sales_user.id,
        user_id=client_user.id,
        final_price=20000000,
    )
    db_session.add(customer)
    await db_session.commit()

    from app.core.security import create_access_token
    client_token = create_access_token(str(client_user.id), client_user.role.value)
    client_headers = {"Authorization": f"Bearer {client_token}"}

    # Inverter ticket without images -> succeeds
    create_res = await client.post(
        "/api/v1/client/tickets",
        json={
            "type": "inverter",
            "title": "Inverter showing red LED",
            "description": "Red error light blinking on inverter display.",
            "error_code": "E-04",
        },
        headers=client_headers,
    )
    assert create_res.status_code == 201
    ticket_id = create_res.json()["id"]

    # Staff assigns ticket
    assign_res = await client.post(
        f"/api/v1/tickets/{ticket_id}/assign",
        json={"assigned_to": str(sample_sales_user.id)},
        headers=auth_headers,
    )
    assert assign_res.status_code == 200
    assert assign_res.json()["status"] == "assigned"
    assert assign_res.json()["assigned_to"] == str(sample_sales_user.id)

    # Add staff comment
    comm_res = await client.post(
        f"/api/v1/tickets/{ticket_id}/comments",
        json={"message": "Technician scheduled to visit tomorrow at 11 AM."},
        headers=auth_headers,
    )
    assert comm_res.status_code == 201
    assert comm_res.json()["message"] == "Technician scheduled to visit tomorrow at 11 AM."

    # Staff marks as resolved
    resolve_res = await client.post(
        f"/api/v1/tickets/{ticket_id}/status",
        json={
            "status": "resolved",
            "resolution_note": "Replaced faulty DC fuse and rebooted inverter.",
        },
        headers=auth_headers,
    )
    assert resolve_res.status_code == 200
    assert resolve_res.json()["status"] == "resolved"
    assert resolve_res.json()["resolution_note"] == "Replaced faulty DC fuse and rebooted inverter."

    # Client reopens within 7 days -> succeeds
    reopen_res = await client.post(
        f"/api/v1/client/tickets/{ticket_id}/reopen",
        json={"reason": "Error LED started blinking again this morning."},
        headers=client_headers,
    )
    assert reopen_res.status_code == 200
    assert reopen_res.json()["status"] == "reopened"
