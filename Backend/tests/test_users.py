import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.enums import TeamType, UserRole
from app.models.team import Team
from app.models.user import User


@pytest.mark.asyncio
async def test_admin_create_users_and_role_guard(client: AsyncClient, db_session: AsyncSession):
    # Create Admin user
    admin = User(name="Super Admin", phone="9999999999", role=UserRole.ADMIN, is_active=True)
    # Create Sales user
    sales = User(name="Sales Agent", phone="8888888888", role=UserRole.SALES, is_active=True)
    # Create a Team
    team = Team(name="Structure Team 1", type=TeamType.STRUCTURE)

    db_session.add_all([admin, sales, team])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales)
    await db_session.refresh(team)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    sales_token = create_access_token(subject=str(sales.id), role="sales")

    # 1. Sales user tries to create a user -> 403 Forbidden
    sales_resp = await client.post(
        "/api/v1/users",
        headers={"Authorization": f"Bearer {sales_token}"},
        json={"name": "New User", "phone": "7777777777", "role": "sales"},
    )
    assert sales_resp.status_code == 403

    # 2. Admin creates Labour without team_id -> 400 Bad Request
    labour_no_team = await client.post(
        "/api/v1/users",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": "Labour Person", "phone": "7777777777", "role": "labour"},
    )
    assert labour_no_team.status_code == 400
    assert "team_id is required" in labour_no_team.json()["error"]["message"]

    # 3. Admin creates Labour with valid team_id -> 201 Created
    labour_success = await client.post(
        "/api/v1/users",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={
            "name": "Labour Person",
            "phone": "7777777777",
            "role": "labour",
            "team_id": str(team.id),
        },
    )
    assert labour_success.status_code == 201
    created_user_id = labour_success.json()["id"]

    # 4. Admin lists users
    list_resp = await client.get(
        "/api/v1/users",
        headers={"Authorization": f"Bearer {admin_token}"},
        params={"role": "labour"},
    )
    assert list_resp.status_code == 200
    assert list_resp.json()["total"] == 1
    assert list_resp.json()["items"][0]["phone"] == "7777777777"

    # 5. Admin updates user
    patch_resp = await client.patch(
        f"/api/v1/users/{created_user_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": "Updated Labour Name"},
    )
    assert patch_resp.status_code == 200
    assert patch_resp.json()["name"] == "Updated Labour Name"

    # 6. Admin soft-deletes user
    del_resp = await client.delete(
        f"/api/v1/users/{created_user_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert del_resp.status_code == 200

    # 7. Get user after deletion returns 404
    get_del = await client.get(
        f"/api/v1/users/{created_user_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert get_del.status_code == 404
