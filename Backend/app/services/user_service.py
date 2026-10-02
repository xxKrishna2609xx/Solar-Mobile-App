import math
import uuid
from typing import Optional, Tuple
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import BadRequestException, ConflictException, NotFoundException
from app.models.enums import UserRole
from app.models.team import Team
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.user import UserCreate, UserRead, UserUpdate


class UserService:
    """Service handling User management and employee operations."""

    @staticmethod
    async def create_user(db: AsyncSession, user_in: UserCreate) -> User:
        # 1. Check if phone is already taken
        phone_stmt = select(User).where(
            User.phone == user_in.phone,
            User.is_deleted == False,  # noqa: E712
        )
        existing = (await db.execute(phone_stmt)).scalar_one_or_none()
        if existing:
            raise ConflictException(f"User with phone number '{user_in.phone}' already exists.")

        # 2. If labour, validate team_id
        if user_in.role == UserRole.LABOUR:
            if not user_in.team_id:
                raise BadRequestException("A valid team_id is required for users with the 'labour' role.")
            team = (await db.execute(select(Team).where(Team.id == user_in.team_id))).scalar_one_or_none()
            if not team:
                raise NotFoundException("Specified team does not exist.")
        elif user_in.team_id is not None:
            # Non-labour users generally don't have a team, but if provided ensure team exists
            team = (await db.execute(select(Team).where(Team.id == user_in.team_id))).scalar_one_or_none()
            if not team:
                raise NotFoundException("Specified team does not exist.")

        user = User(
            name=user_in.name,
            phone=user_in.phone,
            role=user_in.role,
            team_id=user_in.team_id,
            is_active=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User:
        stmt = select(User).where(
            User.id == user_id,
            User.is_deleted == False,  # noqa: E712
        )
        user = (await db.execute(stmt)).scalar_one_or_none()
        if not user:
            raise NotFoundException("User not found.")
        return user

    @staticmethod
    async def list_users(
        db: AsyncSession,
        page: int = 1,
        page_size: int = 20,
        role: Optional[UserRole] = None,
        team_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> PaginatedResponse[UserRead]:
        query = select(User).where(User.is_deleted == False)  # noqa: E712

        if role is not None:
            query = query.where(User.role == role)
        if team_id is not None:
            query = query.where(User.team_id == team_id)
        if is_active is not None:
            query = query.where(User.is_active == is_active)
        if search:
            search_pattern = f"%{search.strip()}%"
            query = query.where(
                or_(
                    User.name.ilike(search_pattern),
                    User.phone.like(search_pattern),
                )
            )

        # Count total
        count_stmt = select(func.count()).select_from(query.subquery())
        total = (await db.execute(count_stmt)).scalar() or 0

        # Paginate
        query = query.order_by(User.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
        result = await db.execute(query)
        users = list(result.scalars().all())

        pages = math.ceil(total / page_size) if total > 0 else 0

        return PaginatedResponse(
            items=[UserRead.model_validate(u) for u in users],
            total=total,
            page=page,
            page_size=page_size,
            pages=pages,
        )

    @staticmethod
    async def update_user(db: AsyncSession, user_id: uuid.UUID, user_in: UserUpdate) -> User:
        user = await UserService.get_user_by_id(db, user_id)

        if user_in.phone is not None and user_in.phone != user.phone:
            stmt = select(User).where(
                User.phone == user_in.phone,
                User.id != user_id,
                User.is_deleted == False,  # noqa: E712
            )
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if existing:
                raise ConflictException(f"User with phone '{user_in.phone}' already exists.")
            user.phone = user_in.phone

        target_role = user_in.role if user_in.role is not None else user.role
        target_team_id = user_in.team_id if user_in.team_id is not None else user.team_id

        if target_role == UserRole.LABOUR and not target_team_id:
            raise BadRequestException("Labour users must be assigned to a team.")

        if user_in.team_id is not None:
            team = (await db.execute(select(Team).where(Team.id == user_in.team_id))).scalar_one_or_none()
            if not team:
                raise NotFoundException("Specified team does not exist.")
            user.team_id = user_in.team_id

        if user_in.name is not None:
            user.name = user_in.name
        if user_in.role is not None:
            user.role = user_in.role
        if user_in.is_active is not None:
            user.is_active = user_in.is_active

        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def delete_user(db: AsyncSession, user_id: uuid.UUID) -> None:
        user = await UserService.get_user_by_id(db, user_id)
        user.is_deleted = True
        user.is_active = False
        await db.commit()
