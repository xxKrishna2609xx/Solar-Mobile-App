from unittest.mock import AsyncMock, patch
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.customer import Customer
from app.models.enums import CustomerStage, SystemPhase, UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_full_payment_lifecycle_and_stage_advance(client: AsyncClient, db_session: AsyncSession):
    admin = User(name="Admin", phone="9000000040", role=UserRole.ADMIN, is_active=True)
    sales = User(name="Sales Agent", phone="9000000041", role=UserRole.SALES, is_active=True)
    client_user = User(name="Client Customer", phone="9000000042", role=UserRole.CLIENT, is_active=True)

    db_session.add_all([admin, sales, client_user])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales)
    await db_session.refresh(client_user)

    # Customer in DOCUMENTS_RECEIVED stage with final price 2,00,000 INR (20000000 paise)
    customer = Customer(
        name="Sunil Sharma",
        mobile="9000000042",
        address="15 M.G. Road, Pune",
        sales_id=sales.id,
        user_id=client_user.id,
        final_price=20000000,
        capacity_kw=4.0,
        phase=SystemPhase.SINGLE,
        panel_brand="Waaree",
        panel_watt=540,
        panel_count=8,
        inverter_brand="Luminous",
        structure_type="Ground Elevated",
        stage=CustomerStage.DOCUMENTS_RECEIVED,
    )
    db_session.add(customer)
    await db_session.commit()
    await db_session.refresh(customer)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    sales_token = create_access_token(subject=str(sales.id), role="sales")
    client_token = create_access_token(subject=str(client_user.id), role="client")

    with patch("app.services.payment_service.storage_service.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.payment_service.storage_service.get_presigned_url", new_callable=AsyncMock) as mock_url:

        mock_upload.return_value = "mock_proof_key"
        mock_url.return_value = "https://minio.local/presigned-proof.jpg"

        # 1. Client submits 1st payment: 50,000 INR (5000000 paise)
        pay1_resp = await client.post(
            f"/api/v1/customers/{customer.id}/payments",
            headers={"Authorization": f"Bearer {client_token}"},
            data={
                "amount": 5000000,
                "mode": "upi",
                "reference_no": "UPI123456789",
                "remarks": "Advance token payment",
            },
            files={"file": ("receipt.jpg", b"\xff\xd8\xff dummy", "image/jpeg")},
        )
        assert pay1_resp.status_code == 201
        pay1 = pay1_resp.json()
        pay1_id = pay1["id"]
        assert pay1["status"] == "pending"
        assert pay1["stage_no"] == 1
        assert len(pay1["audit_logs"]) >= 1

        # 2. Sales checks pending queue and sees the payment
        queue_resp = await client.get(
            "/api/v1/payments/pending",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert queue_resp.status_code == 200
        assert any(p["id"] == pay1_id for p in queue_resp.json())

        # 3. Client tries to sales-approve own payment -> 403 Forbidden
        client_approve = await client.post(
            f"/api/v1/payments/{pay1_id}/sales-approve",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert client_approve.status_code == 403

        # 4. Sales approves payment -> becomes sales_approved
        sales_app = await client.post(
            f"/api/v1/payments/{pay1_id}/sales-approve",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert sales_app.status_code == 200
        assert sales_app.json()["status"] == "sales_approved"

        # 5. Sales tries to admin-verify -> 403 Forbidden
        sales_verify = await client.post(
            f"/api/v1/payments/{pay1_id}/verify",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert sales_verify.status_code == 403

        # 6. Admin verifies payment -> becomes verified
        admin_verify = await client.post(
            f"/api/v1/payments/{pay1_id}/verify",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert admin_verify.status_code == 200
        assert admin_verify.json()["status"] == "verified"

        # 7. Customer stage auto-moves from DOCUMENTS_RECEIVED to ADVANCE_VERIFIED
        cust_check = await client.get(
            f"/api/v1/customers/{customer.id}",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert cust_check.status_code == 200
        assert cust_check.json()["stage"] == "ADVANCE_VERIFIED"
        assert cust_check.json()["payment_summary"]["received_amount_paise"] == 5000000
        assert cust_check.json()["payment_summary"]["balance_paise"] == 15000000
        assert cust_check.json()["payment_summary"]["status"] == "partially_paid"


@pytest.mark.asyncio
async def test_overpayment_and_rejection_guard(client: AsyncClient, db_session: AsyncSession):
    admin = User(name="Admin", phone="9000000050", role=UserRole.ADMIN, is_active=True)
    sales = User(name="Sales", phone="9000000051", role=UserRole.SALES, is_active=True)
    client_user = User(name="Client", phone="9000000052", role=UserRole.CLIENT, is_active=True)

    db_session.add_all([admin, sales, client_user])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales)
    await db_session.refresh(client_user)

    # Customer final price: 1,00,000 INR (10000000 paise)
    customer = Customer(
        name="Anita Sen",
        mobile="9000000052",
        address="20 Park Street, Kolkata",
        sales_id=sales.id,
        user_id=client_user.id,
        final_price=10000000,
        capacity_kw=2.0,
        phase=SystemPhase.SINGLE,
        panel_brand="Tata",
        panel_watt=500,
        panel_count=4,
        inverter_brand="Microtek",
        structure_type="Roof",
        stage=CustomerStage.SALE_CONFIRMED,
    )
    db_session.add(customer)
    await db_session.commit()
    await db_session.refresh(customer)

    admin_token = create_access_token(subject=str(admin.id), role="admin")
    sales_token = create_access_token(subject=str(sales.id), role="sales")

    # 1. Overpayment: Attempting to record 1,50,000 INR (15000000 paise) when price is 1,00,000 INR
    overpay_resp = await client.post(
        f"/api/v1/customers/{customer.id}/payments",
        headers={"Authorization": f"Bearer {admin_token}"},
        data={"amount": 15000000, "mode": "bank_transfer"},
    )
    assert overpay_resp.status_code == 400
    assert "exceed total final price" in overpay_resp.json()["error"]["message"]

    # 2. Record valid payment: 80,000 INR
    valid_pay = await client.post(
        f"/api/v1/customers/{customer.id}/payments",
        headers={"Authorization": f"Bearer {sales_token}"},
        data={"amount": 8000000, "mode": "cash"},
    )
    assert valid_pay.status_code == 201
    pay_id = valid_pay.json()["id"]

    # 3. Reject payment with reason
    reject_resp = await client.post(
        f"/api/v1/payments/{pay_id}/reject",
        headers={"Authorization": f"Bearer {admin_token}"},
        json={"reason": "Cash not received by cashier"},
    )
    assert reject_resp.status_code == 200
    assert reject_resp.json()["status"] == "rejected"
    assert reject_resp.json()["rejection_reason"] == "Cash not received by cashier"
