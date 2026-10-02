import io
from unittest.mock import AsyncMock, patch
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import create_access_token
from app.models.customer import Customer
from app.models.enums import CustomerStage, SystemPhase, UserRole
from app.models.user import User


@pytest.mark.asyncio
async def test_document_upload_and_auto_stage_progression(client: AsyncClient, db_session: AsyncSession):
    # Setup Admin and Sales
    admin = User(name="Admin", phone="9000000030", role=UserRole.ADMIN, is_active=True)
    sales = User(name="Sales", phone="9000000031", role=UserRole.SALES, is_active=True)
    client_user = User(name="Customer User", phone="9000000032", role=UserRole.CLIENT, is_active=True)

    db_session.add_all([admin, sales, client_user])
    await db_session.commit()
    await db_session.refresh(admin)
    await db_session.refresh(sales)
    await db_session.refresh(client_user)

    customer = Customer(
        name="Sunil Verma",
        mobile="9000000032",
        address="10 Civil Lines, Kota",
        sales_id=sales.id,
        user_id=client_user.id,
        final_price=30000000,
        capacity_kw=6.0,
        phase=SystemPhase.THREE,
        panel_brand="Tata Power",
        panel_watt=550,
        panel_count=12,
        inverter_brand="Havells",
        structure_type="Standard Galvanized",
        stage=CustomerStage.SALE_CONFIRMED,
    )
    db_session.add(customer)
    await db_session.commit()
    await db_session.refresh(customer)

    sales_token = create_access_token(subject=str(sales.id), role="sales")
    admin_token = create_access_token(subject=str(admin.id), role="admin")

    # Mock storage service upload and presigned URL
    with patch("app.services.document_service.storage_service.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.document_service.storage_service.get_presigned_url", new_callable=AsyncMock) as mock_url, \
         patch("app.services.document_service.storage_service.delete_file", new_callable=AsyncMock) as mock_delete:

        mock_upload.return_value = "mock_key"
        mock_url.return_value = "https://minio.local/presigned-url"
        mock_delete.return_value = True

        # 1. Invalid file extension -> 400 Bad Request
        bad_ext = await client.post(
            f"/api/v1/customers/{customer.id}/documents",
            headers={"Authorization": f"Bearer {sales_token}"},
            data={"type": "e_bill"},
            files={"file": ("test.exe", b"binary content", "application/octet-stream")},
        )
        assert bad_ext.status_code == 400
        assert "Unsupported file extension" in bad_ext.json()["error"]["message"]

        # 2. Upload mandatory document 1: e_bill
        doc1 = await client.post(
            f"/api/v1/customers/{customer.id}/documents",
            headers={"Authorization": f"Bearer {sales_token}"},
            data={"type": "e_bill"},
            files={"file": ("bill.pdf", b"%PDF-1.4 dummy", "application/pdf")},
        )
        assert doc1.status_code == 201
        doc1_id = doc1.json()["id"]
        assert doc1.json()["download_url"] == "https://minio.local/presigned-url"

        # 3. Upload remaining mandatory docs: aadhaar, pan, cancelled_cheque, registry
        for doc_type in ["aadhaar", "pan", "cancelled_cheque", "registry"]:
            resp = await client.post(
                f"/api/v1/customers/{customer.id}/documents",
                headers={"Authorization": f"Bearer {sales_token}"},
                data={"type": doc_type},
                files={"file": (f"{doc_type}.jpg", b"\xff\xd8\xff dummy jpeg", "image/jpeg")},
            )
            assert resp.status_code == 201

        # 4. Customer stage should have auto-progressed to DOCUMENTS_RECEIVED
        cust_check = await client.get(
            f"/api/v1/customers/{customer.id}",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert cust_check.status_code == 200
        assert cust_check.json()["stage"] == "DOCUMENTS_RECEIVED"
        assert cust_check.json()["documents_count"] == 5

        # 5. List documents
        doc_list = await client.get(
            f"/api/v1/customers/{customer.id}/documents",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert doc_list.status_code == 200
        assert len(doc_list.json()) == 5

        # 6. Delete document
        del_resp = await client.delete(
            f"/api/v1/documents/{doc1_id}",
            headers={"Authorization": f"Bearer {sales_token}"},
        )
        assert del_resp.status_code == 200
