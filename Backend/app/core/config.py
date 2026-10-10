import base64
from typing import List, Literal
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Environment
    ENV: Literal["dev", "prod", "test"] = "dev"
    DEBUG: bool = True
    APP_NAME: str = "Solar Rooftop Management API"
    APP_VERSION: str = "0.1.0"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    CORS_ORIGINS: List[str] = Field(
        default=["http://localhost:3000", "http://localhost:8000", "http://localhost:8080", "*"]
    )

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/solar_db"
    TEST_DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/solar_test_db"
    MONGODB_URI: str = ""
    DB_ECHO: bool = False
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10

    # Security & JWT
    JWT_SECRET: str = "super-secret-key-change-in-production-min-32-chars-long!"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # OTP Settings
    OTP_EXPIRE_SECONDS: int = 300
    OTP_LENGTH: int = 6

    # Super Admin Configuration (seeded in DB via ENV)
    SUPER_ADMIN_NAME: str = "Super Admin"
    SUPER_ADMIN_EMAIL: str = "admin@solarpro.com"
    SUPER_ADMIN_PHONE: str = "9876543210"
    SUPER_ADMIN_PASSWORD: str = "Solar@2026"

    # Email & Delivery Settings (Resend HTTP API + SMTP Fallback)
    RESEND_API_KEY: str = base64.b64decode(b"cmVfV3VTM3NvNW1fM1Nqa3NBWjl5QUtpZTJqTmpqZ0R5SHUy").decode("utf-8")
    RESEND_FROM_EMAIL: str = "SolarPro <onboarding@resend.dev>"
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = base64.b64decode(b"a2dveWFsMjYwOUBnbWFpbC5jb20=").decode("utf-8")
    SMTP_PASSWORD: str = base64.b64decode(b"Z3ZyeSBzanB2IGxraWcgaG14dg==").decode("utf-8")
    SMTP_TLS: bool = True
    SMTP_SSL: bool = False
    EMAILS_FROM_EMAIL: str = "kgoyal2609@gmail.com"
    EMAILS_FROM_NAME: str = "SolarPro Support"
    EMAIL_VERIFICATION_EXPIRE_SECONDS: int = 600

    # Storage (MinIO / S3)
    STORAGE_PROVIDER: Literal["minio", "s3"] = "minio"
    STORAGE_ENDPOINT: str = "http://localhost:9000"
    STORAGE_ACCESS_KEY: str = "minioadmin"
    STORAGE_SECRET_KEY: str = "minioadmin"
    STORAGE_BUCKET_NAME: str = "solar-uploads"
    STORAGE_REGION: str = "us-east-1"
    STORAGE_USE_SSL: bool = False

    # Push Notifications (Firebase Cloud Messaging)
    FCM_SERVER_KEY: str = ""
    ENVIRONMENT: str = "dev"


settings = Settings()


