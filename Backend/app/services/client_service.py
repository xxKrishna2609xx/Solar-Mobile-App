from datetime import datetime
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import NotFoundException
from app.models.customer import Customer, StageHistory
from app.models.enums import CustomerStage, UserRole, WorkStatus
from app.models.kedl import KedlFile
from app.models.user import User
from app.models.work_assignment import WorkAssignment
from app.schemas.client import ClientHomeResponse, ResponsibleContact, TimelineStageItem
from app.schemas.customer import CustomerRead
from app.services.customer_service import CustomerService

STAGE_ORDER = [
    (CustomerStage.SALE_CONFIRMED, "Sale Confirmed"),
    (CustomerStage.DOCUMENTS_RECEIVED, "Documents Received"),
    (CustomerStage.ADVANCE_VERIFIED, "Advance Payment Verified"),
    (CustomerStage.STRUCTURE_WORK, "Structure Installation"),
    (CustomerStage.ELECTRICAL_WORK, "Electrical Wiring & Inverter"),
    (CustomerStage.CIVIL_WORK, "Civil Works"),
    (CustomerStage.INSTALLATION_COMPLETE, "Installation Complete"),
    (CustomerStage.KEDL_PROCESS, "KEDL Discom Paperwork"),
    (CustomerStage.SYSTEM_LIVE, "System Live & Net Metering"),
    (CustomerStage.HANDED_OVER, "Project Handed Over"),
]


class ClientService:
    """Service providing aggregate home status and profile data for mobile clients."""

    @staticmethod
    async def get_client_customer(db: AsyncSession, current_user: User) -> Customer:
        stmt = select(Customer).where(
            Customer.user_id == current_user.id,
            Customer.is_deleted == False,  # noqa: E712
        )
        customer = (await db.execute(stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("No active solar project found for your mobile number.")
        return customer

    @staticmethod
    async def get_home_data(db: AsyncSession, current_user: User) -> ClientHomeResponse:
        customer = await ClientService.get_client_customer(db, current_user)
        customer_read = await CustomerService.get_customer_by_id(db, customer.id, current_user)

        # 1. Build Stage History Lookup
        histories = customer.stage_histories or []
        history_map: Dict[CustomerStage, StageHistory] = {}
        for h in histories:
            if h.to_stage not in history_map:
                history_map[h.to_stage] = h

        # 2. Build 10-Stage Timeline
        stage_keys = [s[0] for s in STAGE_ORDER]
        current_idx = stage_keys.index(customer.stage) if customer.stage in stage_keys else 0

        timeline: List[TimelineStageItem] = []
        for idx, (stage_enum, title) in enumerate(STAGE_ORDER):
            if idx < current_idx:
                status_str = "done"
            elif idx == current_idx:
                status_str = "current"
            else:
                status_str = "upcoming"

            history_entry = history_map.get(stage_enum)
            dt = history_entry.created_at if history_entry else None
            note = history_entry.note if history_entry else None

            timeline.append(
                TimelineStageItem(
                    stage=stage_enum,
                    title=title,
                    status=status_str,
                    date=dt,
                    note=note,
                )
            )

        # 3. Sales Contact
        sales_contact = ResponsibleContact(
            name=customer.sales_agent.name if customer.sales_agent else "Sales Support",
            phone=customer.sales_agent.phone if customer.sales_agent else "",
            role_title="Sales Executive",
        )

        # 4. Determine Current Responsible Employee
        responsible_contact = sales_contact
        if customer.stage in [
            CustomerStage.STRUCTURE_WORK,
            CustomerStage.ELECTRICAL_WORK,
            CustomerStage.CIVIL_WORK,
            CustomerStage.INSTALLATION_COMPLETE,
        ]:
            # Look for active work assignment
            work_stmt = (
                select(WorkAssignment)
                .where(
                    WorkAssignment.customer_id == customer.id,
                    WorkAssignment.status.in_([WorkStatus.IN_PROGRESS, WorkStatus.PENDING]),
                )
                .order_by(WorkAssignment.scheduled_start.asc())
            )
            active_work = (await db.execute(work_stmt)).scalar_one_or_none()
            if active_work and active_work.team:
                responsible_contact = ResponsibleContact(
                    name=f"{active_work.team.name} Lead",
                    phone=customer.sales_agent.phone if customer.sales_agent else "",
                    role_title=f"{active_work.work_type.value.capitalize()} Installation Team",
                )
        elif customer.stage == CustomerStage.KEDL_PROCESS:
            kedl_stmt = select(KedlFile).where(
                KedlFile.customer_id == customer.id,
                KedlFile.assigned_to.is_not(None),
            )
            kfile = (await db.execute(kedl_stmt)).scalar_one_or_none()
            if kfile and kfile.assignee:
                responsible_contact = ResponsibleContact(
                    name=kfile.assignee.name,
                    phone=kfile.assignee.phone,
                    role_title="KEDL Paperwork Officer",
                )

        # 5. System Specs
        system_specs = {
            "capacity_kw": float(customer.capacity_kw),
            "phase": customer.phase.value,
            "panel_brand": customer.panel_brand,
            "panel_watt": customer.panel_watt,
            "panel_count": customer.panel_count,
            "inverter_brand": customer.inverter_brand,
            "structure_type": customer.structure_type,
        }

        return ClientHomeResponse(
            customer=customer_read,
            stage=customer.stage,
            timeline=timeline,
            responsible_contact=responsible_contact,
            sales_contact=sales_contact,
            payment_summary=customer_read.payment_summary,
            system_specs=system_specs,
        )
