from abc import ABC, abstractmethod


class BaseSmsProvider(ABC):
    @abstractmethod
    async def send_otp(self, phone: str, otp_code: str) -> bool:
        """Send OTP to the given phone number."""
        pass
