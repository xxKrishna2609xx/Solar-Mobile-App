from datetime import datetime, timedelta, timezone
import random
from typing import List, Optional
import uuid
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import ForbiddenException, NotFoundException, ValidationException
from app.storage.s3 import storage_service
from app.models.customer import Customer
from app.models.enums import CustomerStage, TicketPriority, TicketStatus, TicketType, UserRole
from app.models.ticket import ServiceTicket, TicketComment, TicketImage, TicketStatusLog
from app.models.user import User
from app.schemas.ticket import (
    TicketAssign,
    TicketCommentCreate,
    TicketCommentRead,
    TicketCreate,
    TicketImageRead,
    TicketRead,
    TicketStatusLogRead,
    TicketStatusUpdate,
)


class TicketService:
    @staticmethod
    def _validate_image_count(ticket_type: TicketType, image_count: int) -> None:
        if ticket_type == TicketType.STRUCTURE:
            if image_count < 2 or image_count > 10:
                raise ValidationException("Structure tickets require between 2 and 10 photos.")
        elif ticket_type == TicketType.WIRING:
            if image_count < 1 or image_count > 10:
                raise ValidationException("Wiring tickets require between 1 and 10 photos.")
        elif ticket_type == TicketType.INVERTER:
            if image_count > 10:
                raise ValidationException("Inverter tickets accept at most 10 photos.")

    @staticmethod
    async def _generate_ticket_number(db: AsyncSession) -> str:
        for _ in range(10):
            t_num = f"TCK-{random.randint(100000, 999999)}"
            stmt = select(ServiceTicket).where(ServiceTicket.ticket_no == t_num)
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                return t_num
        return f"TCK-{int(datetime.now(timezone.utc).timestamp())}"

    @staticmethod
    async def create_ticket(
        db: AsyncSession,
        customer: Customer,
        data: TicketCreate,
        user: User,
    ) -> ServiceTicket:
        # Check customer stage prerequisite
        if customer.stage not in [CustomerStage.SYSTEM_LIVE, CustomerStage.HANDED_OVER]:
            raise ValidationException(
                "Service tickets can only be raised after installation is live or handed over."
            )

        # Validate images
        image_keys = data.image_keys or []
        TicketService._validate_image_count(data.type, len(image_keys))

        ticket_no = await TicketService._generate_ticket_number(db)

        ticket = ServiceTicket(
            ticket_no=ticket_no,
            customer_id=customer.id,
            type=data.type,
            title=data.title,
            description=data.description,
            error_code=data.error_code if data.type == TicketType.INVERTER else None,
            status=TicketStatus.OPEN,
            priority=data.priority or TicketPriority.NORMAL,
            created_by=user.id,
        )
        db.add(ticket)
        await db.flush()

        # Add images
        for key in image_keys:
            img = TicketImage(
                ticket_id=ticket.id,
                file_key=key,
                uploaded_by=user.id,
            )
            db.add(img)

        # Add initial log
        log = TicketStatusLog(
            ticket_id=ticket.id,
            from_status=None,
            to_status=TicketStatus.OPEN,
            changed_by=user.id,
            note="Ticket submitted by customer",
        )
        db.add(log)
        await db.commit()

        return await TicketService.get_ticket_by_id(db, ticket.id)

    @staticmethod
    async def get_ticket_by_id(
        db: AsyncSession,
        ticket_id: uuid.UUID,
        for_customer_id: Optional[uuid.UUID] = None,
    ) -> ServiceTicket:
        stmt = (
            select(ServiceTicket)
            .options(
                selectinload(ServiceTicket.images),
                selectinload(ServiceTicket.comments).selectinload(TicketComment.author),
                selectinload(ServiceTicket.status_logs).selectinload(TicketStatusLog.changer),
                selectinload(ServiceTicket.customer),
                selectinload(ServiceTicket.assignee),
                selectinload(ServiceTicket.creator),
            )
            .where(ServiceTicket.id == ticket_id)
        )
        ticket = (await db.execute(stmt)).scalar_one_or_none()
        if not ticket:
            raise NotFoundException("Service ticket not found.")

        if for_customer_id and ticket.customer_id != for_customer_id:
            raise ForbiddenException("You do not have access to this ticket.")

        return ticket

    @staticmethod
    async def list_tickets(
        db: AsyncSession,
        customer_id: Optional[uuid.UUID] = None,
        status: Optional[TicketStatus] = None,
        ticket_type: Optional[TicketType] = None,
        assigned_to: Optional[uuid.UUID] = None,
        limit: int = 50,
        offset: int = 0,
    ) -> List[ServiceTicket]:
        stmt = (
            select(ServiceTicket)
            .options(
                selectinload(ServiceTicket.images),
                selectinload(ServiceTicket.comments).selectinload(TicketComment.author),
                selectinload(ServiceTicket.status_logs).selectinload(TicketStatusLog.changer),
                selectinload(ServiceTicket.customer),
                selectinload(ServiceTicket.assignee),
                selectinload(ServiceTicket.creator),
            )
            .order_by(ServiceTicket.created_at.desc())
            .offset(offset)
            .limit(limit)
        )

        if customer_id:
            stmt = stmt.where(ServiceTicket.customer_id == customer_id)
        if status:
            stmt = stmt.where(ServiceTicket.status == status)
        if ticket_type:
            stmt = stmt.where(ServiceTicket.type == ticket_type)
        if assigned_to:
            stmt = stmt.where(ServiceTicket.assigned_to == assigned_to)

        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def add_comment(
        db: AsyncSession,
        ticket_id: uuid.UUID,
        data: TicketCommentCreate,
        user: User,
        for_customer_id: Optional[uuid.UUID] = None,
    ) -> TicketComment:
        ticket = await TicketService.get_ticket_by_id(db, ticket_id, for_customer_id=for_customer_id)

        comment = TicketComment(
            ticket_id=ticket.id,
            author_id=user.id,
            message=data.message,
        )
        db.add(comment)
        await db.commit()
        await db.refresh(comment)
        return comment

    @staticmethod
    async def assign_ticket(
        db: AsyncSession,
        ticket_id: uuid.UUID,
        data: TicketAssign,
        user: User,
    ) -> ServiceTicket:
        ticket = await TicketService.get_ticket_by_id(db, ticket_id)

        assignee_stmt = select(User).where(User.id == data.assigned_to, User.is_active == True)  # noqa: E712
        assignee = (await db.execute(assignee_stmt)).scalar_one_or_none()
        if not assignee:
            raise NotFoundException("Assigned user not found or inactive.")

        old_status = ticket.status
        ticket.assigned_to = data.assigned_to

        if ticket.status == TicketStatus.OPEN:
            ticket.status = TicketStatus.ASSIGNED

        log = TicketStatusLog(
            ticket_id=ticket.id,
            from_status=old_status,
            to_status=ticket.status,
            changed_by=user.id,
            note=f"Assigned to {assignee.name}",
        )
        db.add(log)
        await db.commit()

        return await TicketService.get_ticket_by_id(db, ticket_id)

    @staticmethod
    async def update_status(
        db: AsyncSession,
        ticket_id: uuid.UUID,
        data: TicketStatusUpdate,
        user: User,
    ) -> ServiceTicket:
        ticket = await TicketService.get_ticket_by_id(db, ticket_id)
        old_status = ticket.status
        new_status = data.status

        if old_status == new_status:
            return ticket

        if new_status == TicketStatus.RESOLVED:
            if not data.resolution_note:
                raise ValidationException("A resolution note is required when resolving a ticket.")
            ticket.resolved_at = datetime.now(timezone.utc)
            ticket.resolution_note = data.resolution_note

        elif new_status == TicketStatus.REOPENED:
            if not ticket.resolved_at:
                raise ValidationException("Only resolved tickets can be reopened.")
            # Check 7-day limit
            days_since = (datetime.now(timezone.utc) - ticket.resolved_at.replace(tzinfo=timezone.utc)).total_seconds() / 86400
            if days_since > 7:
                raise ValidationException("Tickets can only be reopened within 7 days of resolution.")

        ticket.status = new_status

        log = TicketStatusLog(
            ticket_id=ticket.id,
            from_status=old_status,
            to_status=new_status,
            changed_by=user.id,
            note=data.note or (data.resolution_note if new_status == TicketStatus.RESOLVED else None),
        )
        db.add(log)
        await db.commit()

        return await TicketService.get_ticket_by_id(db, ticket_id)

    @staticmethod
    async def reopen_by_client(
        db: AsyncSession,
        ticket_id: uuid.UUID,
        reason: str,
        user: User,
        customer_id: uuid.UUID,
    ) -> ServiceTicket:
        ticket = await TicketService.get_ticket_by_id(db, ticket_id, for_customer_id=customer_id)

        if ticket.status not in [TicketStatus.RESOLVED, TicketStatus.CLOSED]:
            raise ValidationException("Only resolved or closed tickets can be reopened.")

        if not ticket.resolved_at:
            raise ValidationException("Ticket has no resolution timestamp recorded.")

        resolved_tz = ticket.resolved_at if ticket.resolved_at.tzinfo else ticket.resolved_at.replace(tzinfo=timezone.utc)
        days_since = (datetime.now(timezone.utc) - resolved_tz).total_seconds() / 86400
        if days_since > 7:
            raise ValidationException("Tickets can only be reopened within 7 days of resolution.")

        old_status = ticket.status
        ticket.status = TicketStatus.REOPENED

        # Add comment
        comment = TicketComment(
            ticket_id=ticket.id,
            author_id=user.id,
            message=f"Reopen request: {reason}",
        )
        db.add(comment)

        log = TicketStatusLog(
            ticket_id=ticket.id,
            from_status=old_status,
            to_status=TicketStatus.REOPENED,
            changed_by=user.id,
            note=f"Client reopened ticket: {reason}",
        )
        db.add(log)
        await db.commit()

        return await TicketService.get_ticket_by_id(db, ticket_id, for_customer_id=customer_id)

    @staticmethod
    async def build_ticket_read(ticket: ServiceTicket) -> TicketRead:
        storage = storage_service
        images_read: List[TicketImageRead] = []
        for img in ticket.images:
            url = await storage.get_presigned_url(img.file_key)
            images_read.append(
                TicketImageRead(
                    id=img.id,
                    ticket_id=img.ticket_id,
                    file_key=img.file_key,
                    url=url,
                    uploaded_by=img.uploaded_by,
                    created_at=img.created_at,
                )
            )

        comments_read: List[TicketCommentRead] = []
        for c in ticket.comments:
            comments_read.append(
                TicketCommentRead(
                    id=c.id,
                    ticket_id=c.ticket_id,
                    author_id=c.author_id,
                    author_name=c.author.name if c.author else None,
                    author_role=c.author.role.value if c.author else None,
                    message=c.message,
                    created_at=c.created_at,
                )
            )

        logs_read: List[TicketStatusLogRead] = []
        for l in ticket.status_logs:
            logs_read.append(
                TicketStatusLogRead(
                    id=l.id,
                    ticket_id=l.ticket_id,
                    from_status=l.from_status,
                    to_status=l.to_status,
                    changed_by=l.changed_by,
                    changer_name=l.changer.name if l.changer else None,
                    note=l.note,
                    created_at=l.created_at,
                )
            )

        return TicketRead(
            id=ticket.id,
            ticket_no=ticket.ticket_no,
            customer_id=ticket.customer_id,
            customer_name=ticket.customer.name if ticket.customer else None,
            type=ticket.type,
            title=ticket.title,
            description=ticket.description,
            error_code=ticket.error_code,
            status=ticket.status,
            priority=ticket.priority,
            assigned_to=ticket.assigned_to,
            assignee_name=ticket.assignee.name if ticket.assignee else None,
            resolved_at=ticket.resolved_at,
            resolution_note=ticket.resolution_note,
            created_by=ticket.created_by,
            creator_name=ticket.creator.name if ticket.creator else None,
            created_at=ticket.created_at,
            updated_at=ticket.updated_at,
            images=images_read,
            comments=comments_read,
            status_logs=logs_read,
        )
