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
from app.models.document import CustomerDocument
from app.models.enums import CustomerStage, PaymentStatus, UserRole
from app.models.payment import Payment
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.customer import (
    CustomerCreate,
    CustomerRead,
    CustomerStageUpdate,
    CustomerUpdate,
)

STAGE_TRANSITIONS = {
    CustomerStage.SALE_CONFIRMED: [CustomerStage.DOCUMENTS_RECEIVED],
    CustomerStage.DOCUMENTS_RECEIVED: [CustomerStage.ADVANCE_VERIFIED, CustomerStage.SALE_CONFIRMED],
    CustomerStage.ADVANCE_VERIFIED: [CustomerStage.STRUCTURE_WORK],
    CustomerStage.STRUCTURE_WORK: [CustomerStage.ELECTRICAL_WORK],
    CustomerStage.ELECTRICAL_WORK: [CustomerStage.CIVIL_WORK],
    CustomerStage.CIVIL_WORK: [CustomerStage.INSTALLATION_COMPLETE],
    CustomerStage.INSTALLATION_COMPLETE: [CustomerStage.KEDL_PROCESS],
    CustomerStage.KEDL_PROCESS: [CustomerStage.SYSTEM_LIVE],
    CustomerStage.SYSTEM_LIVE: [CustomerStage.HANDED_OVER],
    CustomerStage.HANDED_OVER: [],
}


class CustomerService:
    """Service handling Customer lifecycles, stage changes, and permissions."""

    @staticmethod
    async def create_customer(
        db: AsyncSession,
        customer_in: CustomerCreate,
        creator: User,
    ) -> CustomerRead:
        # 1. Check if customer with mobile exists
        cust_stmt = select(Customer).where(
            Customer.mobile == customer_in.mobile,
            Customer.is_deleted == False,  # noqa: E712
        )
        if (await db.execute(cust_stmt)).scalar_one_or_none():
            raise ConflictException(f"Customer with mobile number '{customer_in.mobile}' already exists.")

        # 2. Determine sales_id
        if creator.role == UserRole.SALES:
            sales_id = creator.id
        elif customer_in.sales_id:
            sales_user = (await db.execute(select(User).where(User.id == customer_in.sales_id, User.is_deleted == False))).scalar_one_or_none()  # noqa: E712
            if not sales_user:
                raise NotFoundException("Assigned sales agent not found.")
            sales_id = customer_in.sales_id
        else:
            sales_id = creator.id

        # 3. Create or fetch Client User for mobile login
        client_user_stmt = select(User).where(
            User.phone == customer_in.mobile,
            User.is_deleted == False,  # noqa: E712
        )
        client_user = (await db.execute(client_user_stmt)).scalar_one_or_none()
        if not client_user:
            client_user = User(
                name=customer_in.name,
                phone=customer_in.mobile,
                role=UserRole.CLIENT,
                is_active=True,
            )
            db.add(client_user)
            await db.flush()

        # 4. Create customer record
        customer = Customer(
            name=customer_in.name,
            mobile=customer_in.mobile,
            address=customer_in.address,
            latitude=customer_in.latitude,
            longitude=customer_in.longitude,
            sales_id=sales_id,
            user_id=client_user.id,
            final_price=customer_in.final_price,
            capacity_kw=customer_in.capacity_kw,
            phase=customer_in.phase,
            panel_brand=customer_in.panel_brand,
            panel_watt=customer_in.panel_watt,
            panel_count=customer_in.panel_count,
            inverter_brand=customer_in.inverter_brand,
            structure_type=customer_in.structure_type,
            stage=CustomerStage.SALE_CONFIRMED,
        )
        db.add(customer)
        await db.flush()

        # 5. Log initial stage history
        history = StageHistory(
            customer_id=customer.id,
            from_stage=None,
            to_stage=CustomerStage.SALE_CONFIRMED,
            changed_by=creator.id,
            note="Sale Confirmed / Customer Created",
        )
        db.add(history)
        await db.commit()
        await db.refresh(customer)

        return await CustomerService.get_customer_by_id(db=db, customer_id=customer.id, current_user=creator)

    @staticmethod
    async def get_customer_by_id(
        db: AsyncSession,
        customer_id: uuid.UUID,
        current_user: User,
    ) -> CustomerRead:
        stmt = select(Customer).where(
            Customer.id == customer_id,
            Customer.is_deleted == False,  # noqa: E712
        )
        customer = (await db.execute(stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        # Permissions check
        if current_user.role == UserRole.SALES and customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only access their own customer records.")
        elif current_user.role == UserRole.CLIENT and customer.user_id != current_user.id:
            raise ForbiddenException("Clients can only access their own customer record.")

        # Document count
        doc_count_stmt = select(func.count(CustomerDocument.id)).where(CustomerDocument.customer_id == customer_id)
        doc_count = (await db.execute(doc_count_stmt)).scalar() or 0

        # Payments summary
        pay_stmt = select(Payment).where(
            Payment.customer_id == customer_id,
            Payment.is_deleted == False,  # noqa: E712
        )
        payments = list((await db.execute(pay_stmt)).scalars().all())
        total_verified = sum(p.amount for p in payments if p.status == PaymentStatus.VERIFIED)
        total_pending = sum(p.amount for p in payments if p.status in [PaymentStatus.PENDING, PaymentStatus.SALES_APPROVED])
        balance = max(0, customer.final_price - total_verified)

        if total_verified >= customer.final_price:
            pay_status = "fully_paid"
        elif total_verified > 0:
            pay_status = "partially_paid"
        else:
            pay_status = "pending"

        res = CustomerRead.model_validate(customer)
        res.documents_count = doc_count
        res.payment_summary = {
            "total_amount_paise": customer.final_price,
            "received_amount_paise": total_verified,
            "pending_amount_paise": total_pending,
            "balance_paise": balance,
            "status": pay_status,
        }
        return res

    @staticmethod
    async def list_customers(
        db: AsyncSession,
        current_user: User,
        page: int = 1,
        page_size: int = 20,
        stage: Optional[CustomerStage] = None,
        sales_id: Optional[uuid.UUID] = None,
        search: Optional[str] = None,
    ) -> PaginatedResponse[CustomerRead]:
        query = select(Customer).where(Customer.is_deleted == False)  # noqa: E712

        # Role scoping
        if current_user.role == UserRole.SALES:
            query = query.where(Customer.sales_id == current_user.id)
        elif current_user.role == UserRole.CLIENT:
            query = query.where(Customer.user_id == current_user.id)
        elif sales_id:
            query = query.where(Customer.sales_id == sales_id)

        if stage is not None:
            query = query.where(Customer.stage == stage)

        if search:
            pattern = f"%{search.strip()}%"
            query = query.where(
                or_(
                    Customer.name.ilike(pattern),
                    Customer.mobile.like(pattern),
                    Customer.address.ilike(pattern),
                )
            )

        # Count total
        count_stmt = select(func.count()).select_from(query.subquery())
        total = (await db.execute(count_stmt)).scalar() or 0

        # Paginate
        query = query.order_by(Customer.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
        result = await db.execute(query)
        customers = list(result.scalars().all())

        items: list[CustomerRead] = []
        for c in customers:
            doc_count_stmt = select(func.count(CustomerDocument.id)).where(CustomerDocument.customer_id == c.id)
            doc_count = (await db.execute(doc_count_stmt)).scalar() or 0
            c_read = CustomerRead.model_validate(c)
            c_read.documents_count = doc_count
            items.append(c_read)

        pages = math.ceil(total / page_size) if total > 0 else 0

        return PaginatedResponse(
            items=items,
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    @staticmethod
    async def update_customer(
        db: AsyncSession,
        customer_id: uuid.UUID,
        customer_in: CustomerUpdate,
        current_user: User,
    ) -> CustomerRead:
        customer = (await db.execute(select(Customer).where(Customer.id == customer_id, Customer.is_deleted == False))).scalar_one_or_none()  # noqa: E712
        if not customer:
            raise NotFoundException("Customer not found.")

        if current_user.role == UserRole.SALES and customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only modify their own customers.")
        elif current_user.role not in [UserRole.ADMIN, UserRole.SALES]:
            raise ForbiddenException("Insufficient permissions to update customer details.")

        for field, value in customer_in.model_dump(exclude_unset=True).items():
            setattr(customer, field, value)

        await db.commit()
        await db.refresh(customer)
        return await CustomerService.get_customer_by_id(db=db, customer_id=customer.id, current_user=current_user)

    @staticmethod
    async def update_customer_stage(
        db: AsyncSession,
        customer_id: uuid.UUID,
        stage_in: CustomerStageUpdate,
        current_user: User,
    ) -> CustomerRead:
        customer = (await db.execute(select(Customer).where(Customer.id == customer_id, Customer.is_deleted == False))).scalar_one_or_none()  # noqa: E712
        if not customer:
            raise NotFoundException("Customer not found.")

        if current_user.role != UserRole.ADMIN:
            raise ForbiddenException("Only administrators can manually update customer stage.")

        # Transition validation
        allowed_next = STAGE_TRANSITIONS.get(customer.stage, [])
        if stage_in.stage not in allowed_next:
            raise BadRequestException(
                f"Invalid stage transition from '{customer.stage.value}' to '{stage_in.stage.value}'. Allowed next stages: {[s.value for s in allowed_next]}"
            )

        old_stage = customer.stage
        customer.stage = stage_in.stage

        history = StageHistory(
            customer_id=customer.id,
            from_stage=old_stage,
            to_stage=stage_in.stage,
            changed_by=current_user.id,
            note=stage_in.note or f"Stage transitioned from {old_stage.value} to {stage_in.stage.value}",
        )
        db.add(history)
        await db.commit()
        await db.refresh(customer)

        return await CustomerService.get_customer_by_id(db=db, customer_id=customer.id, current_user=current_user)
