from datetime import datetime, timezone
import math
import mimetypes
import os
from typing import BinaryIO, List, Optional
import uuid
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import (
    BadRequestException,
    ForbiddenException,
    NotFoundException,
)
from app.models.customer import Customer, StageHistory
from app.models.enums import (
    CustomerStage,
    PaymentAction,
    PaymentMode,
    PaymentStatus,
    UserRole,
)
from app.models.payment import Payment, PaymentAuditLog
from app.models.user import User
from app.schemas.payment import (
    CustomerPaymentsListResponse,
    PaymentAuditLogRead,
    PaymentCreate,
    PaymentRead,
    PaymentSummary,
    PaymentUpdate,
)
from app.storage.s3 import storage_service

ALLOWED_PROOF_EXTS = {".jpg", ".jpeg", ".png", ".pdf"}
ALLOWED_PROOF_MIMES = {"image/jpeg", "image/png", "application/pdf"}
MAX_PROOF_SIZE = 10 * 1024 * 1024


class PaymentService:
    """Service handling multi-stage customer payments, verification workflow, and audit logging."""

    @staticmethod
    async def create_payment(
        db: AsyncSession,
        customer_id: uuid.UUID,
        payment_in: PaymentCreate,
        current_user: User,
        proof_file: Optional[BinaryIO] = None,
        proof_filename: Optional[str] = None,
        proof_content_type: Optional[str] = None,
        proof_size: Optional[int] = None,
        direct_verify: bool = False,
    ) -> PaymentRead:
        # 1. Fetch customer
        cust_stmt = select(Customer).where(Customer.id == customer_id, Customer.is_deleted == False)  # noqa: E712
        customer = (await db.execute(cust_stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        # Permissions check
        if current_user.role == UserRole.CLIENT and customer.user_id != current_user.id:
            raise ForbiddenException("Clients can only submit payments for their own account.")
        elif current_user.role == UserRole.SALES and customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only record payments for their own customers.")

        # 2. Overpayment check (Sum of non-rejected payments + new amount <= final_price)
        sum_stmt = select(func.coalesce(func.sum(Payment.amount), 0)).where(
            Payment.customer_id == customer_id,
            Payment.status != PaymentStatus.REJECTED,
            Payment.is_deleted == False,  # noqa: E712
        )
        current_sum = (await db.execute(sum_stmt)).scalar() or 0
        if current_sum + payment_in.amount > customer.final_price:
            raise BadRequestException(
                f"Payment of {payment_in.amount} paise would exceed total final price ({customer.final_price} paise). Currently recorded: {current_sum} paise."
            )

        # 3. Determine stage sequence number
        count_stmt = select(func.coalesce(func.max(Payment.stage_no), 0)).where(
            Payment.customer_id == customer_id,
            Payment.is_deleted == False,  # noqa: E712
        )
        last_stage_no = (await db.execute(count_stmt)).scalar() or 0
        next_stage_no = last_stage_no + 1

        # 4. Handle proof file upload if provided
        payment_uuid = uuid.uuid4()
        proof_key: Optional[str] = None
        if proof_file and proof_filename:
            _, ext = os.path.splitext(proof_filename.lower())
            if ext not in ALLOWED_PROOF_EXTS:
                raise BadRequestException(f"Invalid proof file extension '{ext}'. Allowed: jpg, png, pdf.")
            if proof_size and proof_size > MAX_PROOF_SIZE:
                raise BadRequestException("Proof file exceeds maximum limit of 10 MB.")

            storage_path = f"customers/{customer_id}/payments/{payment_uuid}{ext}"
            await storage_service.upload_file(
                file_obj=proof_file,
                destination_path=storage_path,
                content_type=proof_content_type or "application/octet-stream",
            )
            proof_key = storage_path

        # 5. Determine initial status
        now = datetime.now(timezone.utc)
        if direct_verify and current_user.role == UserRole.ADMIN:
            initial_status = PaymentStatus.VERIFIED
            verified_by = current_user.id
            verified_at = now
            sales_approved_by = current_user.id
            sales_approved_at = now
        elif current_user.role == UserRole.SALES:
            initial_status = PaymentStatus.SALES_APPROVED
            verified_by = None
            verified_at = None
            sales_approved_by = current_user.id
            sales_approved_at = now
        else:
            initial_status = PaymentStatus.PENDING
            verified_by = None
            verified_at = None
            sales_approved_by = None
            sales_approved_at = None

        payment = Payment(
            id=payment_uuid,
            customer_id=customer_id,
            stage_no=next_stage_no,
            amount=payment_in.amount,
            mode=payment_in.mode,
            reference_no=payment_in.reference_no,
            paid_on=payment_in.paid_on,
            proof_key=proof_key,
            status=initial_status,
            submitted_by=current_user.id,
            submitted_by_role=current_user.role,
            sales_approved_by=sales_approved_by,
            sales_approved_at=sales_approved_at,
            verified_by=verified_by,
            verified_at=verified_at,
            remarks=payment_in.remarks,
        )
        db.add(payment)
        await db.flush()

        # 6. Audit log
        audit = PaymentAuditLog(
            payment_id=payment.id,
            action=PaymentAction.SUBMITTED,
            actor_id=current_user.id,
            old_status=None,
            new_status=initial_status,
            note=f"Payment recorded with status {initial_status.value}",
        )
        db.add(audit)

        # 7. If directly verified, check for customer stage advance
        if initial_status == PaymentStatus.VERIFIED:
            await PaymentService._check_and_advance_stage(db, customer, current_user.id, payment.id)

        await db.commit()
        await db.refresh(payment)

        return await PaymentService._to_payment_read(payment)

    @staticmethod
    async def get_customer_payments(
        db: AsyncSession,
        customer_id: uuid.UUID,
        current_user: User,
    ) -> CustomerPaymentsListResponse:
        cust_stmt = select(Customer).where(Customer.id == customer_id, Customer.is_deleted == False)  # noqa: E712
        customer = (await db.execute(cust_stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        if current_user.role == UserRole.CLIENT and customer.user_id != current_user.id:
            raise ForbiddenException("Clients can only view their own payments.")
        elif current_user.role == UserRole.SALES and customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only view their own customers' payments.")

        # Query all payments
        stmt = (
            select(Payment)
            .where(
                Payment.customer_id == customer_id,
                Payment.is_deleted == False,  # noqa: E712
            )
            .order_by(Payment.stage_no.asc())
        )
        payments = list((await db.execute(stmt)).scalars().all())

        # Totals calculation
        total_verified = sum(p.amount for p in payments if p.status == PaymentStatus.VERIFIED)
        total_pending = sum(
            p.amount for p in payments if p.status in [PaymentStatus.PENDING, PaymentStatus.SALES_APPROVED]
        )
        balance = max(0, customer.final_price - total_verified)

        if total_verified >= customer.final_price:
            summary_status = "fully_paid"
        elif total_verified > 0:
            summary_status = "partially_paid"
        else:
            summary_status = "pending"

        summary = PaymentSummary(
            final_price=customer.final_price,
            total_verified=total_verified,
            total_pending=total_pending,
            balance=balance,
            status=summary_status,
        )

        items = [await PaymentService._to_payment_read(p) for p in payments]
        return CustomerPaymentsListResponse(items=items, summary=summary)

    @staticmethod
    async def list_pending_payments(
        db: AsyncSession,
        current_user: User,
    ) -> List[PaymentRead]:
        """List queue of pending approval payments based on actor role."""
        query = select(Payment).join(Customer).where(Payment.is_deleted == False)  # noqa: E712

        if current_user.role == UserRole.SALES:
            # Sales queue: Pending client payments for own customers
            query = query.where(
                Customer.sales_id == current_user.id,
                Payment.status == PaymentStatus.PENDING,
            )
        elif current_user.role == UserRole.ADMIN:
            # Admin queue: Sales approved (or pending) payments needing verification
            query = query.where(
                Payment.status.in_([PaymentStatus.PENDING, PaymentStatus.SALES_APPROVED]),
            )
        else:
            raise ForbiddenException("Only sales and admin users have a pending payment queue.")

        query = query.order_by(Payment.created_at.asc())
        payments = list((await db.execute(query)).scalars().all())
        return [await PaymentService._to_payment_read(p) for p in payments]

    @staticmethod
    async def sales_approve_payment(
        db: AsyncSession,
        payment_id: uuid.UUID,
        current_user: User,
    ) -> PaymentRead:
        stmt = (
            select(Payment)
            .join(Customer)
            .where(Payment.id == payment_id, Payment.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        payment = (await db.execute(stmt)).scalar_one_or_none()
        if not payment:
            raise NotFoundException("Payment not found.")

        # Permission: assigned sales agent or admin
        if current_user.role == UserRole.SALES and payment.customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only approve payments for their own customers.")
        elif current_user.role not in [UserRole.ADMIN, UserRole.SALES]:
            raise ForbiddenException("Insufficient permissions to approve payment.")

        if payment.status != PaymentStatus.PENDING:
            raise BadRequestException(f"Cannot sales-approve payment with current status '{payment.status.value}'.")

        old_status = payment.status
        now = datetime.now(timezone.utc)
        payment.status = PaymentStatus.SALES_APPROVED
        payment.sales_approved_by = current_user.id
        payment.sales_approved_at = now

        audit = PaymentAuditLog(
            payment_id=payment.id,
            action=PaymentAction.SALES_APPROVED,
            actor_id=current_user.id,
            old_status=old_status,
            new_status=PaymentStatus.SALES_APPROVED,
            note="Payment approved by sales agent",
        )
        db.add(audit)
        await db.commit()
        await db.refresh(payment)

        return await PaymentService._to_payment_read(payment)

    @staticmethod
    async def verify_payment(
        db: AsyncSession,
        payment_id: uuid.UUID,
        admin_user: User,
    ) -> PaymentRead:
        if admin_user.role != UserRole.ADMIN:
            raise ForbiddenException("Only administrators can verify payments.")

        stmt = (
            select(Payment)
            .join(Customer)
            .where(Payment.id == payment_id, Payment.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        payment = (await db.execute(stmt)).scalar_one_or_none()
        if not payment:
            raise NotFoundException("Payment not found.")

        if payment.status not in [PaymentStatus.PENDING, PaymentStatus.SALES_APPROVED]:
            raise BadRequestException(f"Cannot verify payment with status '{payment.status.value}'.")

        old_status = payment.status
        now = datetime.now(timezone.utc)
        payment.status = PaymentStatus.VERIFIED
        payment.verified_by = admin_user.id
        payment.verified_at = now

        audit = PaymentAuditLog(
            payment_id=payment.id,
            action=PaymentAction.VERIFIED,
            actor_id=admin_user.id,
            old_status=old_status,
            new_status=PaymentStatus.VERIFIED,
            note="Payment verified and confirmed by employer/admin",
        )
        db.add(audit)

        # Check and advance customer stage if this is the first verified payment
        await PaymentService._check_and_advance_stage(db, payment.customer, admin_user.id, payment.id)

        await db.commit()
        await db.refresh(payment)

        return await PaymentService._to_payment_read(payment)

    @staticmethod
    async def reject_payment(
        db: AsyncSession,
        payment_id: uuid.UUID,
        reason: str,
        current_user: User,
    ) -> PaymentRead:
        stmt = (
            select(Payment)
            .join(Customer)
            .where(Payment.id == payment_id, Payment.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        payment = (await db.execute(stmt)).scalar_one_or_none()
        if not payment:
            raise NotFoundException("Payment not found.")

        if current_user.role == UserRole.SALES and payment.customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only reject payments for their own customers.")
        elif current_user.role not in [UserRole.ADMIN, UserRole.SALES]:
            raise ForbiddenException("Insufficient permissions to reject payment.")

        if payment.status == PaymentStatus.VERIFIED:
            raise BadRequestException("Cannot reject a payment that has already been verified by admin.")

        old_status = payment.status
        payment.status = PaymentStatus.REJECTED
        payment.rejection_reason = reason

        audit = PaymentAuditLog(
            payment_id=payment.id,
            action=PaymentAction.REJECTED,
            actor_id=current_user.id,
            old_status=old_status,
            new_status=PaymentStatus.REJECTED,
            note=f"Payment rejected: {reason}",
        )
        db.add(audit)
        await db.commit()
        await db.refresh(payment)

        return await PaymentService._to_payment_read(payment)

    @staticmethod
    async def update_payment(
        db: AsyncSession,
        payment_id: uuid.UUID,
        payment_in: PaymentUpdate,
        current_user: User,
    ) -> PaymentRead:
        stmt = (
            select(Payment)
            .join(Customer)
            .where(Payment.id == payment_id, Payment.is_deleted == False)  # noqa: E712
            .with_for_update()
        )
        payment = (await db.execute(stmt)).scalar_one_or_none()
        if not payment:
            raise NotFoundException("Payment not found.")

        if payment.status != PaymentStatus.PENDING:
            raise BadRequestException("Payments can only be edited while in 'pending' status.")

        if current_user.role == UserRole.CLIENT and payment.submitted_by != current_user.id:
            raise ForbiddenException("Clients can only edit their own pending payments.")
        elif current_user.role == UserRole.SALES and payment.customer.sales_id != current_user.id:
            raise ForbiddenException("Sales agents can only edit payments for their own customers.")

        # Check overpayment if amount changed
        if payment_in.amount is not None and payment_in.amount != payment.amount:
            sum_stmt = select(func.coalesce(func.sum(Payment.amount), 0)).where(
                Payment.customer_id == payment.customer_id,
                Payment.id != payment.id,
                Payment.status != PaymentStatus.REJECTED,
                Payment.is_deleted == False,  # noqa: E712
            )
            other_sum = (await db.execute(sum_stmt)).scalar() or 0
            if other_sum + payment_in.amount > payment.customer.final_price:
                raise BadRequestException("Updated payment amount would exceed customer final price.")
            payment.amount = payment_in.amount

        if payment_in.mode is not None:
            payment.mode = payment_in.mode
        if payment_in.reference_no is not None:
            payment.reference_no = payment_in.reference_no
        if payment_in.paid_on is not None:
            payment.paid_on = payment_in.paid_on
        if payment_in.remarks is not None:
            payment.remarks = payment_in.remarks

        audit = PaymentAuditLog(
            payment_id=payment.id,
            action=PaymentAction.UPDATED,
            actor_id=current_user.id,
            old_status=payment.status,
            new_status=payment.status,
            note="Payment details updated while pending",
        )
        db.add(audit)
        await db.commit()
        await db.refresh(payment)

        return await PaymentService._to_payment_read(payment)

    @staticmethod
    async def _check_and_advance_stage(
        db: AsyncSession,
        customer: Customer,
        actor_id: uuid.UUID,
        payment_id: uuid.UUID,
    ) -> None:
        """Advance customer stage from DOCUMENTS_RECEIVED to ADVANCE_VERIFIED on first verified payment."""
        if customer.stage == CustomerStage.DOCUMENTS_RECEIVED:
            customer.stage = CustomerStage.ADVANCE_VERIFIED
            history = StageHistory(
                customer_id=customer.id,
                from_stage=CustomerStage.DOCUMENTS_RECEIVED,
                to_stage=CustomerStage.ADVANCE_VERIFIED,
                changed_by=actor_id,
                note=f"Advance payment verified (Payment ID: {payment_id})",
            )
            db.add(history)

    @staticmethod
    async def _to_payment_read(payment: Payment) -> PaymentRead:
        read_obj = PaymentRead.model_validate(payment)
        if payment.proof_key:
            read_obj.proof_url = await storage_service.get_presigned_url(payment.proof_key, expires_in=3600)
        return read_obj
