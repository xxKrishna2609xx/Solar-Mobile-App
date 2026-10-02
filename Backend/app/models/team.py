from typing import TYPE_CHECKING, List
from sqlalchemy import Enum, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from app.models.enums import TeamType

if TYPE_CHECKING:
    from app.models.user import User


class Team(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "teams"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[TeamType] = mapped_column(
        Enum(TeamType, name="team_type_enum", native_enum=False),
        nullable=False,
        index=True,
    )

    # Relationships
    members: Mapped[List["User"]] = relationship(
        "User",
        back_populates="team",
        lazy="selectin",
    )

    __table_args__ = (
        UniqueConstraint("type", "name", name="uq_team_type_name"),
    )
