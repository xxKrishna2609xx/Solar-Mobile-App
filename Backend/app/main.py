import time
import uuid
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import structlog
from app.api.v1.router import api_v1_router
from app.core.config import settings
from app.core.exceptions import AppException
from app.core.logging import setup_logging

setup_logging()
logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting up Solar Backend Application", version=settings.APP_VERSION, env=settings.ENV)
    try:
        from app.db.mongo import init_mongo
        init_mongo()
    except Exception as e:
        logger.warning("Could not auto-initialize MongoDB on startup", error=str(e))
    yield
    logger.info("Shutting down Solar Backend Application")


def create_application() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # CORS Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Request ID and Logging Middleware
    @app.middleware("http")
    async def request_id_and_logging_middleware(request: Request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=request_id)

        start_time = time.time()
        logger.info(
            "HTTP request started",
            method=request.method,
            path=request.url.path,
        )

        try:
            response = await call_next(request)
            process_time = time.time() - start_time
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Process-Time"] = f"{process_time:.4f}s"
            logger.info(
                "HTTP request completed",
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                process_time=f"{process_time:.4f}s",
            )
            return response
        except Exception as exc:
            process_time = time.time() - start_time
            logger.error(
                "HTTP request unhandled exception",
                method=request.method,
                path=request.url.path,
                error=str(exc),
                process_time=f"{process_time:.4f}s",
                exc_info=True,
            )
            raise exc

    # Exception Handlers
    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "code": exc.code,
                    "message": exc.message,
                    "details": exc.details,
                }
            },
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Request validation failed.",
                    "details": {"errors": exc.errors()},
                }
            },
        )

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "code": "HTTP_ERROR",
                    "message": str(exc.detail),
                    "details": {},
                }
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        logger.error("Unhandled server exception", exc_info=True)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "An internal server error occurred.",
                    "details": {},
                }
            },
        )

    # Mount API routers
    app.include_router(api_v1_router, prefix="/api/v1")

    return app


app = create_application()
