import structlog
from app.services.sms.base import BaseSmsProvider

logger = structlog.get_logger()


class Msg91SmsProvider(BaseSmsProvider):
    def __init__(self, auth_key: str = "", template_id: str = ""):
        self.auth_key = auth_key
        self.template_id = template_id

    async def send_otp(self, phone: str, otp_code: str) -> bool:
        # Placeholder for Msg91 integration via httpx
        logger.info("Msg91 SMS Provider dispatching OTP", phone=phone)
        return True
