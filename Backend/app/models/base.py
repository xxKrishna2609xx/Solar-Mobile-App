from app.db.base import Base, SoftDeleteMixin, TimestampMixin, UUIDPrimaryKeyMixin


class BaseModel(Base, UUIDPrimaryKeyMixin):
    """Abstract base model that combines SQLAlchemy Declarative Base with UUID primary key."""

    __abstract__ = True


__all__ = [
    "Base",
    "BaseModel",
    "UUIDPrimaryKeyMixin",
    "TimestampMixin",
    "SoftDeleteMixin",
]
