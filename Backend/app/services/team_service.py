import uuid
from typing import List, Optional
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import BadRequestException, ConflictException, NotFoundException
from app.models.enums import TeamType
from app.models.team import Team
from app.models.user import User
from app.schemas.team import TeamCreate, TeamUpdate


class TeamService:
    """Service handling Team management business logic."""

    @staticmethod
    async def create_team(db: AsyncSession, team_in: TeamCreate) -> Team:
        stmt = select(Team).where(Team.type == team_in.type, Team.name == team_in.name)
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if existing:
            raise ConflictException(f"Team '{team_in.name}' of type '{team_in.type.value}' already exists.")

        team = Team(name=team_in.name, type=team_in.type)
        db.add(team)
        await db.commit()
        await db.refresh(team)
        return team

    @staticmethod
    async def get_team_by_id(db: AsyncSession, team_id: uuid.UUID) -> Team:
        stmt = select(Team).where(Team.id == team_id)
        team = (await db.execute(stmt)).scalar_one_or_none()
        if not team:
            raise NotFoundException("Team not found.")
        return team

    @staticmethod
    async def list_teams(db: AsyncSession, team_type: Optional[TeamType] = None) -> List[Team]:
        stmt = select(Team)
        if team_type:
            stmt = stmt.where(Team.type == team_type)
        stmt = stmt.order_by(Team.name.asc())
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def update_team(db: AsyncSession, team_id: uuid.UUID, team_in: TeamUpdate) -> Team:
        team = await TeamService.get_team_by_id(db, team_id)

        target_name = team_in.name if team_in.name is not None else team.name
        target_type = team_in.type if team_in.type is not None else team.type

        if target_name != team.name or target_type != team.type:
            stmt = select(Team).where(
                Team.type == target_type,
                Team.name == target_name,
                Team.id != team_id,
            )
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if existing:
                raise ConflictException(f"Team '{target_name}' of type '{target_type.value}' already exists.")

        if team_in.name is not None:
            team.name = team_in.name
        if team_in.type is not None:
            team.type = team_in.type

        await db.commit()
        await db.refresh(team)
        return team

    @staticmethod
    async def delete_team(db: AsyncSession, team_id: uuid.UUID) -> None:
        team = await TeamService.get_team_by_id(db, team_id)

        # Check for active team members
        member_count_stmt = select(func.count(User.id)).where(
            User.team_id == team_id,
            User.is_deleted == False,  # noqa: E712
        )
        member_count = (await db.execute(member_count_stmt)).scalar() or 0
        if member_count > 0:
            raise BadRequestException("Cannot delete team with active members. Please reassign members first.")

        await db.delete(team)
        await db.commit()
