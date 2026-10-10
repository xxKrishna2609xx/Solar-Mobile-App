import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import require_roles
from app.db.session import get_db
from app.models.enums import UserRole
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.user import UserCreate, UserRead, UserUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.post(
    "",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new employee (Admin only)",
)
async def create_user(
    payload: UserCreate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await UserService.create_user(db=db, user_in=payload)


@router.get(
    "",
    response_model=PaginatedResponse[UserRead],
    status_code=status.HTTP_200_OK,
    summary="List all users with filters (Admin only)",
)
async def list_users(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    role: Optional[UserRole] = Query(default=None),
    team_id: Optional[uuid.UUID] = Query(default=None),
    is_active: Optional[bool] = Query(default=None),
    search: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await UserService.list_users(
        db=db,
        page=page,
        page_size=page_size,
        role=role,
        team_id=team_id,
        is_active=is_active,
        search=search,
    )


@router.get(
    "/approvals/list",
    summary="List employee and admin registration requests (Admin/Super Admin only)",
)
async def list_pending_approvals(
    status: str = Query(default="pending"),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    from app.db.mongo import mongo_get_registration_approvals
    return mongo_get_registration_approvals(status=status)


@router.post(
    "/approvals/{user_id}/approve",
    summary="Approve employee or admin registration request (Admin/Super Admin only)",
)
async def approve_registration(
    user_id: str,
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    from app.db.mongo import mongo_approve_user
    user = mongo_approve_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Registration request not found.")

    # Send approval email notification via Resend
    user_email = user.get("email")
    if user_email:
        try:
            from app.services.email_service import email_service
            subject = "Welcome to SolarPro: Your Account is Approved!"
            body_html = f"""
            <p>Hello <strong>{user.get('name', 'User')}</strong>,</p>
            <p>Your registration request for SolarPro has been approved by the Super Admin.</p>
            <p>You may now open the SolarPro app and log in with your credentials.</p>
            """
            import asyncio
            asyncio.create_task(email_service._send_resend(user_email, subject, body_html))
        except Exception:
            pass

    return {"message": "User registration approved successfully.", "user": user}


@router.post(
    "/approvals/{user_id}/reject",
    summary="Reject employee or admin registration request (Admin/Super Admin only)",
)
async def reject_registration(
    user_id: str,
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    from app.db.mongo import mongo_reject_user
    user = mongo_reject_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Registration request not found.")
    return {"message": "User registration request rejected.", "user": user}


@router.get(
    "/{user_id}",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Get user details by ID (Admin only)",
)
async def get_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await UserService.get_user_by_id(db=db, user_id=user_id)


@router.patch(
    "/{user_id}",
    response_model=UserRead,
    status_code=status.HTTP_200_OK,
    summary="Update user details (Admin only)",
)
async def update_user(
    user_id: uuid.UUID,
    payload: UserUpdate,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    return await UserService.update_user(db=db, user_id=user_id, user_in=payload)


@router.delete(
    "/{user_id}",
    status_code=status.HTTP_200_OK,
    summary="Deactivate and soft delete a user (Admin only)",
)
async def delete_user(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    admin_user: User = Depends(require_roles(UserRole.ADMIN)),
):
    await UserService.delete_user(db=db, user_id=user_id)
    return {"message": "User deactivated and deleted successfully."}
