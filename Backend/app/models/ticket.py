from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
import uuid
from sqlalchemy import DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import TicketPriority, TicketStatus, TicketType

if TYPE_CHECKING:
    from app.models.customer import Customer
    from app.models.user import User


class ServiceTicket(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "service_tickets"

    ticket_no: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    type: Mapped[TicketType] = mapped_column(
        Enum(TicketType, name="ticket_type_enum", native_enum=False),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    error_code: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    status: Mapped[TicketStatus] = mapped_column(
        Enum(TicketStatus, name="ticket_status_enum", native_enum=False),
        default=TicketStatus.OPEN,
        nullable=False,
        index=True,
    )
    priority: Mapped[TicketPriority] = mapped_column(
        Enum(TicketPriority, name="ticket_priority_enum", native_enum=False),
        default=TicketPriority.NORMAL,
        nullable=False,
        index=True,
    )

    assigned_to: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    resolution_note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", lazy="joined")
    assignee: Mapped[Optional["User"]] = relationship("User", foreign_keys=[assigned_to], lazy="joined")
    creator: Mapped["User"] = relationship("User", foreign_keys=[created_by], lazy="joined")
    images: Mapped[List["TicketImage"]] = relationship(
        "TicketImage",
        back_populates="ticket",
        cascade="all, delete-orphan",
        order_by="TicketImage.created_at.asc()",
        lazy="selectin",
    )
    comments: Mapped[List["TicketComment"]] = relationship(
        "TicketComment",
        back_populates="ticket",
        cascade="all, delete-orphan",
        order_by="TicketComment.created_at.asc()",
        lazy="selectin",
    )
    status_logs: Mapped[List["TicketStatusLog"]] = relationship(
        "TicketStatusLog",
        back_populates="ticket",
        cascade="all, delete-orphan",
        order_by="TicketStatusLog.created_at.desc()",
        lazy="selectin",
    )


class TicketImage(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "ticket_images"

    ticket_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("service_tickets.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    file_key: Mapped[str] = mapped_column(String(255), nullable=False)
    uploaded_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    ticket: Mapped["ServiceTicket"] = relationship("ServiceTicket", back_populates="images")
    uploader: Mapped[Optional["User"]] = relationship("User", lazy="joined")


class TicketComment(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "ticket_comments"

    ticket_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("service_tickets.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    author_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    message: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    ticket: Mapped["ServiceTicket"] = relationship("ServiceTicket", back_populates="comments")
    author: Mapped[Optional["User"]] = relationship("User", lazy="joined")


class TicketStatusLog(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "ticket_status_logs"

    ticket_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("service_tickets.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    from_status: Mapped[Optional[TicketStatus]] = mapped_column(
        Enum(TicketStatus, name="ticket_status_enum", native_enum=False),
        nullable=True,
    )
    to_status: Mapped[TicketStatus] = mapped_column(
        Enum(TicketStatus, name="ticket_status_enum", native_enum=False),
        nullable=False,
    )
    changed_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    ticket: Mapped["ServiceTicket"] = relationship("ServiceTicket", back_populates="status_logs")
    actor: Mapped[Optional["User"]] = relationship("User", lazy="joined")
