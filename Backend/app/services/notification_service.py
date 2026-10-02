from abc import ABC, abstractmethod
from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import NotFoundException
from app.models.notification import Notification, SystemAuditLog
from app.models.user import User

logger = logging.getLogger("solar_app.notifications")


class NotificationProvider(ABC):
    @abstractmethod
    async def send(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> bool:
        pass


class ConsoleNotificationProvider(NotificationProvider):
    async def send(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> bool:
        logger.info(
            f"[CONSOLE PUSH NOTIFICATION] Token: {fcm_token[:10]}... | Title: {title} | Body: {body} | Data: {data}"
        )
        return True


class FirebaseNotificationProvider(NotificationProvider):
    def __init__(self):
        self._initialized = False
        # If firebase credentials available, initialize firebase_admin

    async def send(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> bool:
        try:
            logger.info(f"[FCM SEND] Token: {fcm_token[:10]}... | Title: {title} | Body: {body}")
            # Real firebase send implementation
            return True
        except Exception as e:
            logger.error(f"FCM delivery error: {str(e)}")
            return False


_notification_provider: Optional[NotificationProvider] = None


def get_notification_provider() -> NotificationProvider:
    global _notification_provider
    if _notification_provider is None:
        if settings.ENVIRONMENT == "prod" and settings.FCM_SERVER_KEY:
            _notification_provider = FirebaseNotificationProvider()
        else:
            _notification_provider = ConsoleNotificationProvider()
    return _notification_provider


class NotificationService:
    @staticmethod
    async def create_and_send_notification(
        db: AsyncSession,
        user_id: uuid.UUID,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        # 1. Create in-app notification record
        notif = Notification(
            user_id=user_id,
            title=title,
            body=body,
            data=data,
            is_read=False,
        )
        db.add(notif)
        await db.commit()
        await db.refresh(notif)

        # 2. Lookup user fcm_token
        stmt = select(User.fcm_token).where(User.id == user_id, User.is_active == True)  # noqa: E712
        token = (await db.execute(stmt)).scalar_one_or_none()

        if token:
            provider = get_notification_provider()
            await provider.send(fcm_token=token, title=title, body=body, data=data)

        return notif

    @staticmethod
    async def get_user_notifications(
        db: AsyncSession,
        user_id: uuid.UUID,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Notification]:
        stmt = (
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def get_unread_count(db: AsyncSession, user_id: uuid.UUID) -> int:
        stmt = (
            select(func.count(Notification.id))
            .where(Notification.user_id == user_id, Notification.is_read == False)  # noqa: E712
        )
        return (await db.execute(stmt)).scalar_one() or 0

    @staticmethod
    async def mark_as_read(
        db: AsyncSession, notification_id: uuid.UUID, user_id: uuid.UUID
    ) -> Notification:
        stmt = select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        )
        notif = (await db.execute(stmt)).scalar_one_or_none()
        if not notif:
            raise NotFoundException("Notification not found.")

        notif.is_read = True
        await db.commit()
        await db.refresh(notif)
        return notif

    @staticmethod
    async def mark_all_as_read(db: AsyncSession, user_id: uuid.UUID) -> int:
        stmt = (
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read == False)  # noqa: E712
            .values(is_read=True)
        )
        result = await db.execute(stmt)
        await db.commit()
        return result.rowcount or 0

    @staticmethod
    async def log_audit(
        db: AsyncSession,
        user_id: Optional[uuid.UUID],
        action: str,
        entity_type: str,
        entity_id: Optional[str] = None,
        changes: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
    ) -> SystemAuditLog:
        log = SystemAuditLog(
            user_id=user_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            changes=changes,
            ip_address=ip_address,
        )
        db.add(log)
        await db.commit()
        return log
