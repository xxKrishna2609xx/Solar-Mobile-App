from datetime import datetime
import math
import uuid
from typing import Optional
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.models.customer import Customer, StageHistory
from app.models.enums import CustomerStage, LeadStatus, UserRole
from app.models.lead import Lead
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.customer import CustomerRead
from app.schemas.lead import (
    LeadAssign,
    LeadConvert,
    LeadCreate,
    LeadMarkLost,
    LeadRead,
    LeadUpdate,
)
from app.services.customer_service import CustomerService


class LeadService:
    """Service handling Lead management, assignment, and conversion."""

    @staticmethod
    async def create_lead(
        db: AsyncSession,
        lead_in: LeadCreate,
        current_user: User,
    ) -> LeadRead:
        if current_user.role == UserRole.SALES:
            assigned_sales_id = current_user.id
        elif lead_in.assigned_sales_id:
            sales_user = (await db.execute(select(User).where(User.id == lead_in.assigned_sales_id, User.is_deleted == False))).scalar_one_or_none()  # noqa: E712
            if not sales_user:
                raise NotFoundException("Assigned sales agent not found.")
            assigned_sales_id = lead_in.assigned_sales_id
        else:
            assigned_sales_id = current_user.id

        lead = Lead(
            name=lead_in.name,
            phone=lead_in.phone,
            address=lead_in.address,
            expected_kw=lead_in.expected_kw,
            source=lead_in.source,
            status=LeadStatus.NEW,
            follow_up_date=lead_in.follow_up_date,
            notes=lead_in.notes,
            assigned_sales_id=assigned_sales_id,
        )
        db.add(lead)
        await db.commit()
        await db.refresh(lead)
        return LeadRead.model_validate(lead)

    @staticmethod
    async def get_lead_by_id(
        db: AsyncSession,
        lead_id: uuid.UUID,
        current_user: User,
    ) -> LeadRead:
        stmt = select(Lead).where(Lead.id == lead_id)
        lead = (await db.execute(stmt)).scalar_one_or_none()
        if not lead:
            raise NotFoundException("Lead not found.")

        if current_user.role == UserRole.SALES and lead.assigned_sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only access their own assigned leads.")

        return LeadRead.model_validate(lead)

    @staticmethod
    async def list_leads(
        db: AsyncSession,
        current_user: User,
        page: int = 1,
        page_size: int = 20,
        status: Optional[LeadStatus] = None,
        assigned_sales_id: Optional[uuid.UUID] = None,
        search: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> PaginatedResponse[LeadRead]:
        query = select(Lead)

        if current_user.role == UserRole.SALES:
            query = query.where(Lead.assigned_sales_id == current_user.id)
        elif assigned_sales_id:
            query = query.where(Lead.assigned_sales_id == assigned_sales_id)

        if status is not None:
            query = query.where(Lead.status == status)

        if search:
            pattern = f"%{search.strip()}%"
            query = query.where(
                or_(
                    Lead.name.ilike(pattern),
                    Lead.phone.like(pattern),
                    Lead.address.ilike(pattern),
                )
            )

        if start_date:
            query = query.where(Lead.created_at >= start_date)
        if end_date:
            query = query.where(Lead.created_at <= end_date)

        # Count total
        count_stmt = select(func.count()).select_from(query.subquery())
        total = (await db.execute(count_stmt)).scalar() or 0

        # Paginate
        query = query.order_by(Lead.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
        result = await db.execute(query)
        leads = list(result.scalars().all())

        pages = math.ceil(total / page_size) if total > 0 else 0

        return PaginatedResponse(
            items=[LeadRead.model_validate(ld) for ld in leads],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    @staticmethod
    async def update_lead(
        db: AsyncSession,
        lead_id: uuid.UUID,
        lead_in: LeadUpdate,
        current_user: User,
    ) -> LeadRead:
        lead = (await db.execute(select(Lead).where(Lead.id == lead_id))).scalar_one_or_none()
        if not lead:
            raise NotFoundException("Lead not found.")

        if current_user.role == UserRole.SALES and lead.assigned_sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only modify their own leads.")

        # Non-admins cannot reassign leads via patch
        if lead_in.assigned_sales_id is not None and lead_in.assigned_sales_id != lead.assigned_sales_id:
            if current_user.role != UserRole.ADMIN:
                raise ForbiddenException("Only administrators can reassign leads.")

        for field, value in lead_in.model_dump(exclude_unset=True).items():
            setattr(lead, field, value)

        await db.commit()
        await db.refresh(lead)
        return LeadRead.model_validate(lead)

    @staticmethod
    async def reassign_lead(
        db: AsyncSession,
        lead_id: uuid.UUID,
        assign_in: LeadAssign,
        current_user: User,
    ) -> LeadRead:
        if current_user.role != UserRole.ADMIN:
            raise ForbiddenException("Only administrators can reassign leads.")

        lead = (await db.execute(select(Lead).where(Lead.id == lead_id))).scalar_one_or_none()
        if not lead:
            raise NotFoundException("Lead not found.")

        sales_user = (await db.execute(select(User).where(User.id == assign_in.assigned_sales_id, User.is_deleted == False))).scalar_one_or_none()  # noqa: E712
        if not sales_user:
            raise NotFoundException("Target sales user not found.")

        lead.assigned_sales_id = assign_in.assigned_sales_id
        await db.commit()
        await db.refresh(lead)
        return LeadRead.model_validate(lead)

    @staticmethod
    async def mark_lost(
        db: AsyncSession,
        lead_id: uuid.UUID,
        lost_in: LeadMarkLost,
        current_user: User,
    ) -> LeadRead:
        lead = (await db.execute(select(Lead).where(Lead.id == lead_id))).scalar_one_or_none()
        if not lead:
            raise NotFoundException("Lead not found.")

        if current_user.role == UserRole.SALES and lead.assigned_sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only mark their own leads as lost.")

        if lead.status == LeadStatus.CONVERTED:
            raise BadRequestException("Cannot mark a converted lead as lost.")

        lead.status = LeadStatus.LOST
        lead.lost_reason = lost_in.reason
        await db.commit()
        await db.refresh(lead)
        return LeadRead.model_validate(lead)

    @staticmethod
    async def convert_lead(
        db: AsyncSession,
        lead_id: uuid.UUID,
        convert_in: LeadConvert,
        current_user: User,
    ) -> CustomerRead:
        lead = (await db.execute(select(Lead).where(Lead.id == lead_id))).scalar_one_or_none()
        if not lead:
            raise NotFoundException("Lead not found.")

        if current_user.role == UserRole.SALES and lead.assigned_sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only convert their own leads.")

        if lead.status == LeadStatus.CONVERTED:
            raise BadRequestException("Lead is already converted.")

        # Check if customer mobile already exists
        cust_stmt = select(Customer).where(Customer.mobile == lead.phone, Customer.is_deleted == False)  # noqa: E712
        if (await db.execute(cust_stmt)).scalar_one_or_none():
            raise ConflictException(f"A customer with mobile number '{lead.phone}' already exists.")

        # 1. Create or get client user
        client_user_stmt = select(User).where(User.phone == lead.phone, User.is_deleted == False)  # noqa: E712
        client_user = (await db.execute(client_user_stmt)).scalar_one_or_none()
        if not client_user:
            client_user = User(
                name=lead.name,
                phone=lead.phone,
                role=UserRole.CLIENT,
                is_active=True,
            )
            db.add(client_user)
            await db.flush()

        # 2. Create customer record
        customer = Customer(
            name=lead.name,
            mobile=lead.phone,
            address=convert_in.address,
            latitude=convert_in.latitude,
            longitude=convert_in.longitude,
            sales_id=lead.assigned_sales_id,
            user_id=client_user.id,
            final_price=convert_in.final_price,
            capacity_kw=convert_in.capacity_kw,
            phase=convert_in.phase,
            panel_brand=convert_in.panel_brand,
            panel_watt=convert_in.panel_watt,
            panel_count=convert_in.panel_count,
            inverter_brand=convert_in.inverter_brand,
            structure_type=convert_in.structure_type,
            stage=CustomerStage.SALE_CONFIRMED,
        )
        db.add(customer)
        await db.flush()

        # 3. Create initial stage history
        history = StageHistory(
            customer_id=customer.id,
            from_stage=None,
            to_stage=CustomerStage.SALE_CONFIRMED,
            changed_by=current_user.id,
            note=f"Converted from Lead '{lead.name}' (ID: {lead.id})",
        )
        db.add(history)

        # 4. Mark lead as converted and link customer
        lead.status = LeadStatus.CONVERTED
        lead.customer_id = customer.id

        await db.commit()
        await db.refresh(customer)

        return await CustomerService.get_customer_by_id(db=db, customer_id=customer.id, current_user=current_user)
