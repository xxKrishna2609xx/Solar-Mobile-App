import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.enums import TeamType, UserRole
from app.models.team import Team
from app.models.user import User


@pytest.mark.asyncio
async def test_team_crud_and_deletion_protection(client: AsyncClient, db_session: AsyncSession):
    admin = User(name="Admin", phone="9111111111", role=UserRole.ADMIN, is_active=True)
    sales = User(name="Sales", phone="9222222222", role=UserRole.SALES, is_active=True)
    db_session.add_all([admin, sales])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    sales_token = create_access_token(subject=str(sales.id), role="sales")

    # 1. Admin creates team
    team_resp = await client.post(
        "/api/v1/teams",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"name": "Alpha Electrical", "type": "electrical"},
    )
    assert team_resp.status_code == 201
    team_id = team_resp.json()["id"]

    # 2. Sales lists teams
    list_resp = await client.get(
        "/api/v1/teams",
        headers={"Authorization": f"Bearer {sales_token}"},
        params={"type": "electrical"},
    )
    assert list_resp.status_code == 200
    assert len(list_resp.json()) == 1

    # 3. Add active user to the team
    labour = User(
        name="Team Member",
        phone="9333333333",
        role=UserRole.LABOUR,
        team_id=team_id,
        is_active=True,
    )
    db_session.add(labour)
    await db_session.commit()

    # 4. Attempt to delete team with active member -> 400 Bad Request
    del_fail = await client.delete(
        f"/api/v1/teams/{team_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert del_fail.status_code == 400
    assert "Cannot delete team with active members" in del_fail.json()["error"]["message"]

    # 5. Soft-delete user and delete team -> succeeds
    labour.is_deleted = True
    await db_session.commit()

    del_success = await client.delete(
        f"/api/v1/teams/{team_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert del_success.status_code == 200
