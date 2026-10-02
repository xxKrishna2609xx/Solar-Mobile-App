import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import UserRole
from app.models.user import User
from app.services.notification_service import NotificationService


@pytest.mark.asyncio
async def test_notifications_lifecycle(
    client: AsyncClient,
    db_session: AsyncSession,
    auth_headers: dict,
    admin_user: User,
):
    # 1. Create notifications for admin user
    await NotificationService.create_and_send_notification(
        db=db_session,
        user_id=admin_user.id,
        title="Payment Verified",
        body="Advance payment of Rs 50,000 was verified.",
        data={"customer_id": "123"},
    )
    await NotificationService.create_and_send_notification(
        db=db_session,
        user_id=admin_user.id,
        title="Work Assigned",
        body="Structure work assigned for project.",
    )

    # 2. Get unread count
    unread_res = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    assert unread_res.status_code == 200
    assert unread_res.json()["unread_count"] == 2

    # 3. List notifications
    list_res = await client.get("/api/v1/notifications", headers=auth_headers)
    assert list_res.status_code == 200
    notifs = list_res.json()
    assert len(notifs) >= 2
    first_id = notifs[0]["id"]

    # 4. Mark one as read
    read_res = await client.post(f"/api/v1/notifications/{first_id}/read", headers=auth_headers)
    assert read_res.status_code == 200
    assert read_res.json()["is_read"] is True

    # 5. Check unread count is now 1
    unread_res2 = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    assert unread_res2.json()["unread_count"] == 1

    # 6. Mark all as read
    all_res = await client.post("/api/v1/notifications/read-all", headers=auth_headers)
    assert all_res.status_code == 200

    unread_res3 = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
    assert unread_res3.json()["unread_count"] == 0


@pytest.mark.asyncio
async def test_reports_dashboard_and_excel(
    client: AsyncClient,
    auth_headers: dict,
):
    # 1. Get Operations Dashboard KPIs
    dash_res = await client.get("/api/v1/reports/dashboard", headers=auth_headers)
    assert dash_res.status_code == 200
    d_data = dash_res.json()
    assert "total_leads" in d_data
    assert "total_customers" in d_data
    assert "sales_this_month_paise" in d_data

    # 2. Get Sales Performance Report
    sales_res = await client.get("/api/v1/reports/sales", headers=auth_headers)
    assert sales_res.status_code == 200
    assert "sales_reps" in sales_res.json()

    # 3. Get Payments Report
    pay_res = await client.get("/api/v1/reports/payments", headers=auth_headers)
    assert pay_res.status_code == 200
    assert "total_billed_paise" in pay_res.json()

    # 4. Download Customers Excel
    cust_excel = await client.get("/api/v1/reports/export/customers", headers=auth_headers)
    assert cust_excel.status_code == 200
    assert cust_excel.headers["content-type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    assert len(cust_excel.content) > 0

    # 5. Download Payments Excel
    pay_excel = await client.get("/api/v1/reports/export/payments", headers=auth_headers)
    assert pay_excel.status_code == 200
    assert len(pay_excel.content) > 0

    # 6. Download Inventory Excel
    inv_excel = await client.get("/api/v1/reports/export/inventory", headers=auth_headers)
    assert inv_excel.status_code == 200
    assert len(inv_excel.content) > 0
