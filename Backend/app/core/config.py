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
    DEV_MOCK_OTP: str = "123456"

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

