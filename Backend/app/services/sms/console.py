import structlog
from app.services.sms.base import BaseSmsProvider

logger = structlog.get_logger()


class ConsoleSmsProvider(BaseSmsProvider):
    async def send_otp(self, phone: str, otp_code: str) -> bool:
        logger.info("[DEV OTP] Sent SMS", phone=phone, otp=otp_code)
        return True
