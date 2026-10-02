from datetime import date, datetime, timezone
import os
from typing import BinaryIO, Dict, List, Optional
import uuid
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
)
from app.models.customer import Customer, StageHistory
from app.models.enums import (
    CustomerStage,
    KedlDemandStatus,
    KedlFileStatus,
    KedlFileType,
    UserRole,
)
from app.models.kedl import KedlDemand, KedlDocument, KedlFile, KedlStatusLog
from app.models.user import User
from app.schemas.kedl import (
    KedlDashboardMetrics,
    KedlDemandCreate,
    KedlDemandRead,
    KedlDemandUpdate,
    KedlDocumentRead,
    KedlFileInitRequest,
    KedlFileRead,
    KedlFileStatusUpdate,
    KedlFileUpdate,
)
from app.storage.s3 import storage_service

ALLOWED_KEDL_EXTS = {".jpg", ".jpeg", ".png", ".pdf"}
MAX_KEDL_FILE_SIZE = 10 * 1024 * 1024

KEDL_STATUS_TRANSITIONS = {
    KedlFileStatus.NOT_STARTED: [KedlFileStatus.SUBMITTED, KedlFileStatus.DEMAND_RAISED],
    KedlFileStatus.SUBMITTED: [KedlFileStatus.DEMAND_RAISED, KedlFileStatus.APPROVED, KedlFileStatus.REJECTED],
    KedlFileStatus.DEMAND_RAISED: [KedlFileStatus.DEMAND_PAID, KedlFileStatus.REJECTED],
    KedlFileStatus.DEMAND_PAID: [KedlFileStatus.APPROVED, KedlFileStatus.DEMAND_RAISED, KedlFileStatus.REJECTED],
    KedlFileStatus.APPROVED: [],
    KedlFileStatus.REJECTED: [KedlFileStatus.SUBMITTED, KedlFileStatus.DEMAND_RAISED],
}


class KedlService:
    """Service handling KEDL paperwork lifecycle, demands, and discom approvals."""

    @staticmethod
    async def init_customer_files(
        db: AsyncSession,
        customer_id: uuid.UUID,
        init_in: KedlFileInitRequest,
        current_user: User,
    ) -> List[KedlFileRead]:
        # 1. Fetch customer
        cust_stmt = select(Customer).where(Customer.id == customer_id, Customer.is_deleted == False)  # noqa: E712
        customer = (await db.execute(cust_stmt)).scalar_one_or_none()
        if not customer:
            raise NotFoundException("Customer not found.")

        # 2. Check if already initialized
        existing_stmt = select(KedlFile).where(KedlFile.customer_id == customer_id, KedlFile.is_deleted == False)  # noqa: E712
        if (await db.execute(existing_stmt)).scalars().first():
            raise ConflictException("KEDL paperwork files are already initialized for this customer.")

        # 3. Validate assigned KEDL employee
        assigned_to_id = init_in.assigned_to
        if assigned_to_id:
            user_stmt = select(User).where(User.id == assigned_to_id, User.is_deleted == False)  # noqa: E712
            assigned_user = (await db.execute(user_stmt)).scalar_one_or_none()
            if not assigned_user:
                raise NotFoundException("Assigned KEDL employee not found.")
            if assigned_user.role not in [UserRole.KEDL, UserRole.ADMIN]:
                raise BadRequestException("User assigned to KEDL paperwork must have role 'kedl' or 'admin'.")

        # 4. Create the three files: name_change, load, net
        file_types = [KedlFileType.NAME_CHANGE, KedlFileType.LOAD, KedlFileType.NET]
        created_files: List[KedlFile] = []

        for ftype in file_types:
            kedl_file = KedlFile(
                customer_id=customer_id,
                file_type=ftype,
                status=KedlFileStatus.NOT_STARTED,
                assigned_to=assigned_to_id,
            )
            db.add(kedl_file)
            created_files.append(kedl_file)

        await db.flush()

        for kfile in created_files:
            log = KedlStatusLog(
                kedl_file_id=kfile.id,
                from_status=None,
                to_status=KedlFileStatus.NOT_STARTED,
                changed_by=current_user.id,
                note=f"Initialized {kfile.file_type.value} file",
            )
            db.add(log)

        # 5. Move customer stage to KEDL_PROCESS if appropriate
        valid_stages_for_kedl = [
            CustomerStage.ADVANCE_VERIFIED,
            CustomerStage.STRUCTURE_WORK,
            CustomerStage.ELECTRICAL_WORK,
            CustomerStage.CIVIL_WORK,
            CustomerStage.INSTALLATION_COMPLETE,
        ]
        if customer.stage in valid_stages_for_kedl and customer.stage != CustomerStage.KEDL_PROCESS:
            old_stage = customer.stage
            customer.stage = CustomerStage.KEDL_PROCESS
            history = StageHistory(
                customer_id=customer.id,
                from_stage=old_stage,
                to_stage=CustomerStage.KEDL_PROCESS,
                changed_by=current_user.id,
                note="KEDL paperwork process initialized",
            )
            db.add(history)

        await db.commit()

        results: List[KedlFileRead] = []
        for f in created_files:
            await db.refresh(f)
            results.append(await KedlService._to_read(f))

        return results

    @staticmethod
    async def list_kedl_files(
        db: AsyncSession,
        current_user: User,
        customer_id: Optional[uuid.UUID] = None,
        file_type: Optional[KedlFileType] = None,
        status: Optional[KedlFileStatus] = None,
        assigned_to: Optional[uuid.UUID] = None,
        has_open_demand: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> List[KedlFileRead]:
        query = select(KedlFile).join(Customer).where(KedlFile.is_deleted == False)  # noqa: E712

        # Role scoping
        if current_user.role == UserRole.KEDL:
            query = query.where(KedlFile.assigned_to == current_user.id)
        elif assigned_to:
            query = query.where(KedlFile.assigned_to == assigned_to)

        if customer_id:
            query = query.where(KedlFile.customer_id == customer_id)
        if file_type:
            query = query.where(KedlFile.file_type == file_type)
        if status:
            query = query.where(KedlFile.status == status)

        if has_open_demand is not None:
            if has_open_demand:
                query = query.where(
                    KedlFile.demands.any(KedlDemand.status == KedlDemandStatus.OPEN)
                )
            else:
                query = query.where(
                    ~KedlFile.demands.any(KedlDemand.status == KedlDemandStatus.OPEN)
                )

        if search:
            pattern = f"%{search.strip()}%"
            query = query.where(
                or_(
                    Customer.name.ilike(pattern),
                    Customer.mobile.like(pattern),
                    KedlFile.application_no.ilike(pattern),
                )
            )

        query = query.order_by(KedlFile.created_at.desc())
        files = list((await db.execute(query)).scalars().all())

        return [await KedlService._to_read(f) for f in files]

    @staticmethod
    async def get_kedl_file_by_id(
        db: AsyncSession,
        file_id: uuid.UUID,
        current_user: User,
    ) -> KedlFileRead:
        stmt = select(KedlFile).where(KedlFile.id == file_id, KedlFile.is_deleted == False)  # noqa: E712
        kfile = (await db.execute(stmt)).scalar_one_or_none()
        if not kfile:
            raise NotFoundException("KEDL file not found.")

        if current_user.role == UserRole.KEDL and kfile.assigned_to != current_user.id:
            raise ForbiddenException("KEDL employees can only access their assigned files.")

        return await KedlService._to_read(kfile)

    @staticmethod
    async def update_kedl_file(
        db: AsyncSession,
        file_id: uuid.UUID,
        file_in: KedlFileUpdate,
        current_user: User,
    ) -> KedlFileRead:
        stmt = select(KedlFile).where(KedlFile.id == file_id, KedlFile.is_deleted == False)  # noqa: E712
        kfile = (await db.execute(stmt)).scalar_one_or_none()
        if not kfile:
            raise NotFoundException("KEDL file not found.")

        if current_user.role == UserRole.KEDL and kfile.assigned_to != current_user.id:
            raise ForbiddenException("KEDL employees can only edit their assigned files.")

        if file_in.assigned_to is not None and file_in.assigned_to != kfile.assigned_to:
            if current_user.role != UserRole.ADMIN:
                raise ForbiddenException("Only administrators can reassign KEDL files.")
            kfile.assigned_to = file_in.assigned_to

        if file_in.application_no is not None:
            kfile.application_no = file_in.application_no
        if file_in.remarks is not None:
            kfile.remarks = file_in.remarks

        await db.commit()
        await db.refresh(kfile)
        return await KedlService._to_read(kfile)

    @staticmethod
    async def update_file_status(
        db: AsyncSession,
        file_id: uuid.UUID,
        status_in: KedlFileStatusUpdate,
        current_user: User,
    ) -> KedlFileRead:
        stmt = select(KedlFile).where(KedlFile.id == file_id, KedlFile.is_deleted == False)  # noqa: E712
        kfile = (await db.execute(stmt)).scalar_one_or_none()
        if not kfile:
            raise NotFoundException("KEDL file not found.")

        if current_user.role == UserRole.KEDL and kfile.assigned_to != current_user.id:
            raise ForbiddenException("KEDL employees can only update their assigned files.")

        allowed = KEDL_STATUS_TRANSITIONS.get(kfile.status, [])
        if status_in.status not in allowed:
            raise BadRequestException(
                f"Invalid status transition from '{kfile.status.value}' to '{status_in.status.value}'. Allowed: {[s.value for s in allowed]}"
            )

        old_status = kfile.status
        now = datetime.now(timezone.utc)
        kfile.status = status_in.status

        if status_in.status == KedlFileStatus.SUBMITTED and not kfile.submitted_on:
            kfile.submitted_on = now
        elif status_in.status == KedlFileStatus.APPROVED and not kfile.approved_on:
            kfile.approved_on = now

        log = KedlStatusLog(
            kedl_file_id=kfile.id,
            from_status=old_status,
            to_status=status_in.status,
            changed_by=current_user.id,
            note=status_in.note or f"Status changed to {status_in.status.value}",
        )
        db.add(log)

        # If Net file is APPROVED, progress customer stage to SYSTEM_LIVE
        if kfile.file_type == KedlFileType.NET and status_in.status == KedlFileStatus.APPROVED:
            if kfile.customer.stage != CustomerStage.SYSTEM_LIVE:
                old_cust_stage = kfile.customer.stage
                kfile.customer.stage = CustomerStage.SYSTEM_LIVE
                history = StageHistory(
                    customer_id=kfile.customer.id,
                    from_stage=old_cust_stage,
                    to_stage=CustomerStage.SYSTEM_LIVE,
                    changed_by=current_user.id,
                    note="Net metering approved by discom. Solar system is now live!",
                )
                db.add(history)

        await db.commit()
        await db.refresh(kfile)
        return await KedlService._to_read(kfile)

    @staticmethod
    async def raise_demand(
        db: AsyncSession,
        file_id: uuid.UUID,
        demand_in: KedlDemandCreate,
        current_user: User,
    ) -> KedlDemandRead:
        stmt = select(KedlFile).where(KedlFile.id == file_id, KedlFile.is_deleted == False)  # noqa: E712
        kfile = (await db.execute(stmt)).scalar_one_or_none()
        if not kfile:
            raise NotFoundException("KEDL file not found.")

        if current_user.role == UserRole.KEDL and kfile.assigned_to != current_user.id:
            raise ForbiddenException("KEDL employees can only raise demands on their assigned files.")

        demand = KedlDemand(
            kedl_file_id=file_id,
            description=demand_in.description,
            amount=demand_in.amount,
            due_date=demand_in.due_date,
            status=KedlDemandStatus.OPEN,
            raised_by=current_user.id,
        )
        db.add(demand)

        # Transition file status to DEMAND_RAISED
        if kfile.status != KedlFileStatus.DEMAND_RAISED:
            old_file_status = kfile.status
            kfile.status = KedlFileStatus.DEMAND_RAISED
            log = KedlStatusLog(
                kedl_file_id=kfile.id,
                from_status=old_file_status,
                to_status=KedlFileStatus.DEMAND_RAISED,
                changed_by=current_user.id,
                note=f"Demand raised: {demand_in.description}",
            )
            db.add(log)

        await db.commit()
        await db.refresh(demand)

        return KedlDemandRead.model_validate(demand)

    @staticmethod
    async def update_demand(
        db: AsyncSession,
        demand_id: uuid.UUID,
        demand_in: KedlDemandUpdate,
        current_user: User,
        receipt_file: Optional[BinaryIO] = None,
        receipt_filename: Optional[str] = None,
        receipt_content_type: Optional[str] = None,
    ) -> KedlDemandRead:
        stmt = select(KedlDemand).join(KedlFile).where(KedlDemand.id == demand_id)
        demand = (await db.execute(stmt)).scalar_one_or_none()
        if not demand:
            raise NotFoundException("KEDL demand not found.")

        kfile = demand.kedl_file
        if current_user.role == UserRole.KEDL and kfile.assigned_to != current_user.id:
            raise ForbiddenException("KEDL employees can only update demands on their assigned files.")

        # Upload receipt if provided
        if receipt_file and receipt_filename:
            _, ext = os.path.splitext(receipt_filename.lower())
            if ext not in ALLOWED_KEDL_EXTS:
                raise BadRequestException(f"Invalid receipt extension '{ext}'. Allowed: jpg, png, pdf.")
            receipt_uuid = uuid.uuid4()
            storage_path = f"customers/{kfile.customer_id}/kedl/{kfile.file_type.value}/demands/{receipt_uuid}{ext}"
            await storage_service.upload_file(
                file_obj=receipt_file,
                destination_path=storage_path,
                content_type=receipt_content_type or "application/octet-stream",
            )
            demand.receipt_key = storage_path

        demand.status = demand_in.status
        if demand_in.status == KedlDemandStatus.PAID:
            demand.paid_on = demand_in.paid_on or datetime.now(timezone.utc)

        # Check if all open demands for this file are resolved
        open_demands_stmt = select(func.count(KedlDemand.id)).where(
            KedlDemand.kedl_file_id == kfile.id,
            KedlDemand.id != demand.id,
            KedlDemand.status == KedlDemandStatus.OPEN,
        )
        remaining_open = (await db.execute(open_demands_stmt)).scalar() or 0
        if remaining_open == 0:
            if kfile.status == KedlFileStatus.DEMAND_RAISED:
                kfile.status = KedlFileStatus.DEMAND_PAID
                log = KedlStatusLog(
                    kedl_file_id=kfile.id,
                    from_status=KedlFileStatus.DEMAND_RAISED,
                    to_status=KedlFileStatus.DEMAND_PAID,
                    changed_by=current_user.id,
                    note="All pending demands have been resolved/paid",
                )
                db.add(log)

        await db.commit()
        await db.refresh(demand)

        read_item = KedlDemandRead.model_validate(demand)
        if demand.receipt_key:
            read_item.receipt_url = await storage_service.get_presigned_url(demand.receipt_key, expires_in=3600)
        return read_item

    @staticmethod
    async def upload_document(
        db: AsyncSession,
        file_id: uuid.UUID,
        doc_type: str,
        file_obj: BinaryIO,
        filename: str,
        content_type: str,
        size_bytes: int,
        current_user: User,
    ) -> KedlDocumentRead:
        stmt = select(KedlFile).where(KedlFile.id == file_id, KedlFile.is_deleted == False)  # noqa: E712
        kfile = (await db.execute(stmt)).scalar_one_or_none()
        if not kfile:
            raise NotFoundException("KEDL file not found.")

        if current_user.role == UserRole.KEDL and kfile.assigned_to != current_user.id:
            raise ForbiddenException("KEDL employees can only upload documents for their assigned files.")

        _, ext = os.path.splitext(filename.lower())
        if ext not in ALLOWED_KEDL_EXTS:
            raise BadRequestException(f"Invalid document extension '{ext}'. Allowed: jpg, png, pdf.")
        if size_bytes > MAX_KEDL_FILE_SIZE:
            raise BadRequestException("Document exceeds maximum size of 10 MB.")

        doc_uuid = uuid.uuid4()
        storage_path = f"customers/{kfile.customer_id}/kedl/{kfile.file_type.value}/docs/{doc_uuid}{ext}"
        await storage_service.upload_file(
            file_obj=file_obj,
            destination_path=storage_path,
            content_type=content_type or "application/octet-stream",
        )

        doc = KedlDocument(
            id=doc_uuid,
            kedl_file_id=file_id,
            doc_type=doc_type,
            file_key=storage_path,
            original_name=filename,
            uploaded_by=current_user.id,
        )
        db.add(doc)
        await db.commit()
        await db.refresh(doc)

        read_item = KedlDocumentRead.model_validate(doc)
        read_item.download_url = await storage_service.get_presigned_url(doc.file_key, expires_in=3600)
        return read_item

    @staticmethod
    async def get_dashboard_metrics(
        db: AsyncSession,
        current_user: User,
    ) -> KedlDashboardMetrics:
        query = select(KedlFile).where(KedlFile.is_deleted == False)  # noqa: E712
        if current_user.role == UserRole.KEDL:
            query = query.where(KedlFile.assigned_to == current_user.id)

        files = list((await db.execute(query)).scalars().all())

        by_type: Dict[str, int] = {t.value: 0 for t in KedlFileType}
        by_status: Dict[str, int] = {s.value: 0 for s in KedlFileStatus}

        file_ids = [f.id for f in files]

        for f in files:
            by_type[f.file_type.value] = by_type.get(f.file_type.value, 0) + 1
            by_status[f.status.value] = by_status.get(f.status.value, 0) + 1

        open_demands_count = 0
        overdue_demands_count = 0

        if file_ids:
            today = date.today()
            demands_stmt = select(KedlDemand).where(
                KedlDemand.kedl_file_id.in_(file_ids),
                KedlDemand.status == KedlDemandStatus.OPEN,
            )
            open_demands = list((await db.execute(demands_stmt)).scalars().all())
            open_demands_count = len(open_demands)
            overdue_demands_count = sum(1 for d in open_demands if d.due_date and d.due_date < today)

        return KedlDashboardMetrics(
            total_files=len(files),
            by_file_type=by_type,
            by_status=by_status,
            open_demands_count=open_demands_count,
            overdue_demands_count=overdue_demands_count,
        )

    @staticmethod
    async def _to_read(kfile: KedlFile) -> KedlFileRead:
        read_obj = KedlFileRead.model_validate(kfile)
        if read_obj.demands:
            for d in read_obj.demands:
                if d.receipt_key:
                    d.receipt_url = await storage_service.get_presigned_url(d.receipt_key, expires_in=3600)
        if read_obj.documents:
            for doc in read_obj.documents:
                doc.download_url = await storage_service.get_presigned_url(doc.file_key, expires_in=3600)
        return read_obj
