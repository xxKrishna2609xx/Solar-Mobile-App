import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import get_current_user, require_roles
from app.db.session import get_db
from app.models.enums import TeamType, UserRole
from app.models.user import User
from app.schemas.team import TeamCreate, TeamRead, TeamUpdate
from app.services.team_service import TeamService

router = APIRouter(prefix="/teams", tags=["Teams"])


@router.post(
    "",
    response_model=TeamRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new labour team (Admin only)",
)
async def create_team(
    payload: TeamCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await TeamService.create_team(db=db, team_in=payload)


@router.get(
    "",
    response_model=List[TeamRead],
    status_code=status.HTTP_200_OK,
    summary="List teams, optionally filter by type (Authenticated)",
)
async def list_teams(
    type: Optional[TeamType] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await TeamService.list_teams(db=db, team_type=type)


@router.get(
    "/{team_id}",
    response_model=TeamRead,
    status_code=status.HTTP_200_OK,
    summary="Get team details by ID (Authenticated)",
)
async def get_team(
    team_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await TeamService.get_team_by_id(db=db, team_id=team_id)


@router.patch(
    "/{team_id}",
    response_model=TeamRead,
    status_code=status.HTTP_200_OK,
    summary="Update team details (Admin only)",
)
async def update_team(
    team_id: uuid.UUID,
    payload: TeamUpdate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await TeamService.update_team(db=db, team_id=team_id, team_in=payload)


@router.delete(
    "/{team_id}",
    status_code=status.HTTP_200_OK,
    summary="Delete a team (Admin only - team must have no active members)",
)
async def delete_team(
    team_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    await TeamService.delete_team(db=db, team_id=team_id)
    return {"message": "Team deleted successfully."}
