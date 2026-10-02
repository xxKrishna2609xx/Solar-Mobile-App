import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.enums import UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_request_and_verify_otp_flow(client: AsyncClient, db_session: AsyncSession):
    # 1. Create a user
    user = User(
        name="Test Sales",
        phone="9876543210",
        role=UserRole.SALES,
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()

    # 2. Request OTP
    req_resp = await client.post("/api/v1/auth/request-otp", json={"phone": "9876543210"})
    assert req_resp.status_code == 200
    assert "dispatched" in req_resp.json()["message"]

    # 3. Verify OTP using mock dev OTP (123456)
    verify_resp = await client.post(
        "/api/v1/auth/verify-otp",
        json={"phone": "9876543210", "otp": "123456"},
    )
    assert verify_resp.status_code == 200
    data = verify_resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["phone"] == "9876543210"
    assert data["user"]["role"] == "sales"

    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # 4. Get /auth/me
    me_resp = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_resp.status_code == 200
    assert me_resp.json()["name"] == "Test Sales"

    # 5. Update FCM token
    fcm_resp = await client.put(
        "/api/v1/auth/me/fcm-token",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"fcm_token": "fcm_sample_token_1234567890"},
    )
    assert fcm_resp.status_code == 200
    assert fcm_resp.json()["fcm_token"] == "fcm_sample_token_1234567890"

    # 6. Refresh token rotation
    ref_resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_resp.status_code == 200
    new_data = ref_resp.json()
    assert new_data["access_token"] != access_token
    assert new_data["refresh_token"] != refresh_token

    # 7. Old refresh token cannot be reused
    old_ref_resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert old_ref_resp.status_code == 401

    # 8. Logout with new refresh token
    logout_resp = await client.post("/api/v1/auth/logout", json={"refresh_token": new_data["refresh_token"]})
    assert logout_resp.status_code == 200

    # 9. Logged out refresh token rejected
    logged_out_ref = await client.post("/api/v1/auth/refresh", json={"refresh_token": new_data["refresh_token"]})
    assert logged_out_ref.status_code == 401


@pytest.mark.asyncio
async def test_wrong_otp(client: AsyncClient, db_session: AsyncSession):
    user = User(
        name="Test User",
        phone="9876500000",
        role=UserRole.CLIENT,
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()

    await client.post("/api/v1/auth/request-otp", json={"phone": "9876500000"})
    resp = await client.post(
        "/api/v1/auth/verify-otp",
        json={"phone": "9876500000", "otp": "000000"},
    )
    assert resp.status_code == 400
    assert "Invalid OTP" in resp.json()["error"]["message"]


@pytest.mark.asyncio
async def test_otp_rate_limiting(client: AsyncClient, db_session: AsyncSession):
    user = User(
        name="Rate Limit User",
        phone="9876599999",
        role=UserRole.ADMIN,
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()

    # Request 3 times
    for _ in range(3):
        r = await client.post("/api/v1/auth/request-otp", json={"phone": "9876599999"})
        assert r.status_code == 200

    # 4th request within 10 minutes should fail
    r4 = await client.post("/api/v1/auth/request-otp", json={"phone": "9876599999"})
    assert r4.status_code == 400
    assert "Too many OTP requests" in r4.json()["error"]["message"]
