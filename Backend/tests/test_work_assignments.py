from datetime import date
from unittest.mock import AsyncMock, patch
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.customer import Customer
from app.models.enums import CustomerStage, SystemPhase, TeamType, UserRole
from app.models.team import Team
from app.models.user import User


@pytest.mark.asyncio
async def test_work_assignment_workflow(client: AsyncClient, db_session: AsyncSession):
    # Setup Admin, Structure Team & Labour member, Electrical Team & Labour member
    admin = User(name="Admin", phone="9000000060", role=UserRole.ADMIN, is_active=True)
    sales = User(name="Sales", phone="9000000061", role=UserRole.SALES, is_active=True)
    client_user = User(name="Client", phone="9000000062", role=UserRole.CLIENT, is_active=True)

    team_struct = Team(name="Structure Alpha", type=TeamType.STRUCTURE)
    team_elec = Team(name="Electrical Beta", type=TeamType.ELECTRICAL)

    db_session.add_all([admin, sales, client_user, team_struct, team_elec])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales)
    await db_session.refresh(client_user)
    await db_session.refresh(team_struct)
    await db_session.refresh(team_elec)

    labour_struct = User(name="Labour A", phone="9000000063", role=UserRole.LABOUR, team_id=team_struct.id, is_active=True)
    labour_elec = User(name="Labour B", phone="9000000064", role=UserRole.LABOUR, team_id=team_elec.id, is_active=True)
    db_session.add_all([labour_struct, labour_elec])
    await db_session.commit()
    await db_session.refresh(labour_struct)
    await db_session.refresh(labour_elec)

    # Customer in ADVANCE_VERIFIED stage
    customer = Customer(
        name="Vikram Rao",
        mobile="9000000062",
        address="100 Ring Road, Bengaluru",
        sales_id=sales.id,
        user_id=client_user.id,
        final_price=35000000,
        capacity_kw=7.0,
        phase=SystemPhase.THREE,
        panel_brand="Tata Power",
        panel_watt=550,
        panel_count=14,
        inverter_brand="SolarEdge",
        structure_type="Elevated GI",
        stage=CustomerStage.ADVANCE_VERIFIED,
    )
    db_session.add(customer)
    await db_session.commit()
    await db_session.refresh(customer)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    labour_struct_token = create_access_token(subject=str(labour_struct.id), role="labour")
    labour_elec_token = create_access_token(subject=str(labour_elec.id), role="labour")

    # 1. Team type mismatch: Assigning electrical team to structure work -> 400 Bad Request
    mismatch_resp = await client.post(
        f"/api/v1/customers/{customer.id}/work-assignments",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "work_type": "structure",
            "team_id": str(team_elec.id),
            "scheduled_start": "2026-10-10",
            "scheduled_end": "2026-10-12",
        },
    )
    assert mismatch_resp.status_code == 400
    assert "Team type mismatch" in mismatch_resp.json()["error"]["message"]

    # 2. Valid assignment of Structure work to Structure team
    assign_resp = await client.post(
        f"/api/v1/customers/{customer.id}/work-assignments",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "work_type": "structure",
            "team_id": str(team_struct.id),
            "scheduled_start": "2026-10-10",
            "scheduled_end": "2026-10-12",
            "notes": "Mount galvanized rails securely",
        },
    )
    assert assign_resp.status_code == 201
    assign_data = assign_resp.json()
    assignment_id = assign_data["id"]
    assert assign_data["status"] == "pending"

    # 3. Labour isolation: Labour from Electrical team sees 0 assignments
    elec_list = await client.get(
        "/api/v1/work-assignments",
        headers={"Authorization": f"Bearer {labour_elec_token}"},
    )
    assert elec_list.status_code == 200
    assert len(elec_list.json()) == 0

    # Labour from Structure team sees 1 assignment
    struct_list = await client.get(
        "/api/v1/work-assignments",
        headers={"Authorization": f"Bearer {labour_struct_token}"},
    )
    assert struct_list.status_code == 200
    assert len(struct_list.json()) == 1
    assert struct_list.json()[0]["id"] == assignment_id
    assert struct_list.json()[0]["customer"]["name"] == "Vikram Rao"

    # 4. Structure labour starts work -> Customer stage transitions to STRUCTURE_WORK
    start_resp = await client.post(
        f"/api/v1/work-assignments/{assignment_id}/start",
        headers={"Authorization": f"Bearer {labour_struct_token}"},
    )
    assert start_resp.status_code == 200
    assert start_resp.json()["status"] == "in_progress"

    cust_check = await client.get(
        f"/api/v1/customers/{customer.id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert cust_check.status_code == 200
    assert cust_check.json()["stage"] == "STRUCTURE_WORK"

    # 5. Attempting to complete work without any photo -> 400 Bad Request
    complete_no_photo = await client.post(
        f"/api/v1/work-assignments/{assignment_id}/complete",
        headers={"Authorization": f"Bearer {labour_struct_token}"},
    )
    assert complete_no_photo.status_code == 400
    assert "At least 1 proof photo is required" in complete_no_photo.json()["error"]["message"]

    # 6. Upload completion photo
    with patch("app.services.work_assignment_service.storage_service.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.work_assignment_service.storage_service.get_presigned_url", new_callable=AsyncMock) as mock_url:

        mock_upload.return_value = "mock_work_photo_key"
        mock_url.return_value = "https://minio.local/presigned-photo.jpg"

        photo_upload = await client.post(
            f"/api/v1/work-assignments/{assignment_id}/photos",
            headers={"Authorization": f"Bearer {labour_struct_token}"},
            files={"files": ("structure_complete.jpg", b"\xff\xd8\xff dummy jpeg", "image/jpeg")},
            data={"captions": ["Structure fully erected and bolted"]},
        )
        assert photo_upload.status_code == 201
        assert len(photo_upload.json()) == 1

        # 7. Complete work now succeeds -> Advances customer stage to INSTALLATION_COMPLETE
        complete_resp = await client.post(
            f"/api/v1/work-assignments/{assignment_id}/complete",
            headers={"Authorization": f"Bearer {labour_struct_token}"},
        )
        assert complete_resp.status_code == 200
        assert complete_resp.json()["status"] == "completed"

        cust_done = await client.get(
            f"/api/v1/customers/{customer.id}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert cust_done.status_code == 200
        assert cust_done.json()["stage"] == "INSTALLATION_COMPLETE"

    # 8. Calendar endpoint returns grouped schedules
    calendar_resp = await client.get(
        "/api/v1/work-assignments/calendar",
        headers={"Authorization": f"Bearer {admin_token}"},
        params={"from_date": "2026-10-01", "to_date": "2026-10-31"},
    )
    assert calendar_resp.status_code == 200
    cal_data = calendar_resp.json()
    assert cal_data["total_assignments"] >= 1
    assert "2026-10-10" in cal_data["by_date"]
    assert "Structure Alpha" in cal_data["by_team"]
