import uuid
from typing import Callable, List, Optional
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.core.security import decode_access_token
from app.db.session import get_db
from app.models.enums import UserRole
from app.models.user import User

security_bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Extract and validate the current authenticated active user from JWT."""
    if not credentials or not credentials.credentials:
        raise UnauthorizedException("Authentication token required.")

    payload = decode_access_token(credentials.credentials)
    user_id_str: Optional[str] = payload.get("sub")

    if not user_id_str:
        raise UnauthorizedException("Invalid token payload.")

    # 1. Check MongoDB Atlas first
    from app.db.mongo import get_mongo_db
    mongo_db = get_mongo_db()
    if mongo_db is not None:
        mongo_user = mongo_db["users"].find_one({"_id": user_id_str, "is_active": True})
        if mongo_user:
            class MongoUserProxy:
                def __init__(self, d):
                    self.id = d["_id"]
                    self.name = d.get("name", "")
                    self.phone = d.get("phone", "")
                    self.email = d.get("email")
                    try:
                        self.role = UserRole(d.get("role", "client"))
                    except Exception:
                        self.role = d.get("role", "client")
                    self.is_active = d.get("is_active", True)
                    self.fcm_token = d.get("fcm_token")
            return MongoUserProxy(mongo_user)

    # 2. Check SQLAlchemy if db is available
    if db is not None:
        try:
            user_uuid = uuid.UUID(user_id_str)
            query = select(User).where(
                User.id == user_uuid,
                User.is_deleted == False,
            )
            result = await db.execute(query)
            user = result.scalar_one_or_none()
            if user:
                if not user.is_active:
                    raise ForbiddenException("User account is deactivated.")
                return user
        except Exception:
            pass

    raise UnauthorizedException("User not found.")


def require_roles(*allowed_roles: UserRole | str) -> Callable[[User], User]:
    """Dependency factory to enforce role-based access control."""
    allowed_role_values = {
        role.value if isinstance(role, UserRole) else str(role)
        for role in allowed_roles
    }

    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        user_role_val = current_user.role.value if isinstance(current_user.role, UserRole) else str(current_user.role)
        if user_role_val not in allowed_role_values:
            raise ForbiddenException(
                f"Operation not permitted. Required roles: {', '.join(allowed_role_values)}"
            )
        return current_user

    return role_checker
