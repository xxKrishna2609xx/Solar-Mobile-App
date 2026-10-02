from datetime import datetime
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import UserRole
from app.models.user import User
from app.schemas.report import (
    DashboardReportResponse,
    KedlReportResponse,
    PaymentsReportResponse,
    SalesReportResponse,
    WorkReportResponse,
)
from app.services.report_service import ReportService

router = APIRouter(prefix="/reports", tags=["Reports & Operations Analytics"])


@router.get(
    "/dashboard",
    response_model=DashboardReportResponse,
    summary="Get overall operations cockpit KPIs (Admin, Manager)",
)
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await ReportService.get_dashboard_report(db)


@router.get(
    "/sales",
    response_model=SalesReportResponse,
    summary="Get sales performance breakdown by salesperson (Admin, Manager)",
)
async def get_sales_report(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await ReportService.get_sales_report(db)


@router.get(
    "/payments",
    response_model=PaymentsReportResponse,
    summary="Get payments collected vs pending summary and mode distribution (Admin, Manager)",
)
async def get_payments_report(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await ReportService.get_payments_report(db)


@router.get(
    "/work",
    response_model=WorkReportResponse,
    summary="Get work completion metrics grouped by installation team (Admin, Manager)",
)
async def get_work_report(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    return await ReportService.get_work_report(db)


@router.get(
    "/kedl",
    response_model=KedlReportResponse,
    summary="Get KEDL discom paperwork progress and demand balance (Admin, Manager)",
)
async def get_kedl_report(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.KEDL)),
):
    return await ReportService.get_kedl_report(db)


# ------------------ EXCEL EXPORTS ------------------
@router.get(
    "/export/customers",
    summary="Download Excel (.xlsx) report of all customer installations (Admin, Manager)",
)
async def export_customers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    excel_stream = await ReportService.export_customers_excel(db)
    filename = f"customers_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    return StreamingResponse(
        excel_stream,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get(
    "/export/payments",
    summary="Download Excel (.xlsx) report of all payment transactions (Admin, Manager)",
)
async def export_payments(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    excel_stream = await ReportService.export_payments_excel(db)
    filename = f"payments_ledger_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    return StreamingResponse(
        excel_stream,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get(
    "/export/inventory",
    summary="Download Excel (.xlsx) report of current inventory and stock status (Admin, Manager)",
)
async def export_inventory(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.ADMIN, UserRole.MANAGER)),
):
    excel_stream = await ReportService.export_inventory_excel(db)
    filename = f"inventory_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx"
    return StreamingResponse(
        excel_stream,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
