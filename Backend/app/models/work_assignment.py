from datetime import date, datetime
from typing import TYPE_CHECKING, List, Optional
import uuid
from sqlalchemy import Date, DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import WorkStatus, WorkType

if TYPE_CHECKING:
    from app.models.customer import Customer
    from app.models.team import Team
    from app.models.user import User


class WorkAssignment(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "work_assignments"

    customer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("customers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    work_type: Mapped[WorkType] = mapped_column(
        Enum(WorkType, name="work_type_enum", native_enum=False),
        nullable=False,
        index=True,
    )
    team_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("teams.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    scheduled_start: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    scheduled_end: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    actual_start: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    actual_end: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[WorkStatus] = mapped_column(
        Enum(WorkStatus, name="work_status_enum", native_enum=False),
        default=WorkStatus.PENDING,
        nullable=False,
        index=True,
    )
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    assigned_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationships
    customer: Mapped["Customer"] = relationship("Customer", lazy="joined")
    team: Mapped["Team"] = relationship("Team", lazy="joined")
    assigner: Mapped[Optional["User"]] = relationship("User", foreign_keys=[assigned_by], lazy="joined")
    photos: Mapped[List["WorkPhoto"]] = relationship(
        "WorkPhoto",
        back_populates="work_assignment",
        cascade="all, delete-orphan",
        order_by="WorkPhoto.created_at.desc()",
        lazy="selectin",
    )
    status_logs: Mapped[List["WorkStatusLog"]] = relationship(
        "WorkStatusLog",
        back_populates="work_assignment",
        cascade="all, delete-orphan",
        order_by="WorkStatusLog.created_at.desc()",
        lazy="selectin",
    )


class WorkPhoto(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "work_photos"

    work_assignment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("work_assignments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    file_key: Mapped[str] = mapped_column(String(255), nullable=False)
    caption: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
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
    work_assignment: Mapped["WorkAssignment"] = relationship("WorkAssignment", back_populates="photos")
    uploader: Mapped[Optional["User"]] = relationship("User", lazy="joined")


class WorkStatusLog(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "work_status_logs"

    work_assignment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("work_assignments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    from_status: Mapped[Optional[WorkStatus]] = mapped_column(
        Enum(WorkStatus, name="work_status_enum", native_enum=False),
        nullable=True,
    )
    to_status: Mapped[WorkStatus] = mapped_column(
        Enum(WorkStatus, name="work_status_enum", native_enum=False),
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
    work_assignment: Mapped["WorkAssignment"] = relationship("WorkAssignment", back_populates="status_logs")
    actor: Mapped[Optional["User"]] = relationship("User", lazy="joined")
