from typing import AsyncGenerator, Optional
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from app.core.config import settings
import structlog

logger = structlog.get_logger()

engine = None
AsyncSessionLocal = None

try:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=settings.DB_ECHO,
        pool_size=settings.DB_POOL_SIZE,
        max_overflow=settings.DB_MAX_OVERFLOW,
        future=True,
    )
    AsyncSessionLocal = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )
except Exception as e:
    logger.warning("Could not initialize PostgreSQL engine; running in MongoDB/standalone mode", error=str(e))


async def get_db() -> AsyncGenerator[Optional[AsyncSession], None]:
    if AsyncSessionLocal is None:
        yield None
        return

    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


