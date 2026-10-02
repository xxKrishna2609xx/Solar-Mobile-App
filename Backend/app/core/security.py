from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import random
import re
import secrets
from typing import Any, Dict, Optional
import jwt
from app.core.config import settings
from app.core.exceptions import UnauthorizedException


def normalize_phone(phone: str) -> str:
    """Normalize phone number to 10-digit format for Indian numbers."""
    cleaned = re.sub(r"\D", "", phone)
    if len(cleaned) == 12 and cleaned.startswith("91"):
        cleaned = cleaned[2:]
    elif len(cleaned) == 11 and cleaned.startswith("0"):
        cleaned = cleaned[1:]
    if len(cleaned) != 10:
        raise ValueError("Invalid phone number. Must be a 10-digit Indian phone number.")
    return cleaned


def hash_token(token: str) -> str:
    """Hash sensitive tokens/OTPs using HMAC-SHA256."""
    return hmac.new(
        settings.JWT_SECRET.encode("utf-8"),
        token.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def verify_token_hash(token: str, token_hash: str) -> bool:
    """Verify a token against its stored hash securely."""
    expected_hash = hash_token(token)
    return hmac.compare_digest(expected_hash, token_hash)


def generate_otp(length: int = 6) -> str:
    """Generate a numeric OTP code."""
    if settings.ENV == "dev" and settings.DEV_MOCK_OTP:
        return settings.DEV_MOCK_OTP
    return "".join(random.choices("0123456789", k=length))


def generate_random_token() -> str:
    """Generate a secure random string for refresh tokens."""
    return secrets.token_urlsafe(48)


def create_access_token(subject: str, role: str, expires_delta: Optional[timedelta] = None) -> str:
    """Generate a signed JWT access token."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode: Dict[str, Any] = {
        "sub": str(subject),
        "role": str(role),
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    }
    return jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> Dict[str, Any]:
    """Decode and validate a JWT access token."""
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
        )
        if payload.get("type") != "access":
            raise UnauthorizedException("Invalid token type.")
        return payload
    except jwt.ExpiredSignatureError:
        raise UnauthorizedException("Token has expired.")
    except jwt.PyJWTError:
        raise UnauthorizedException("Could not validate credentials.")
