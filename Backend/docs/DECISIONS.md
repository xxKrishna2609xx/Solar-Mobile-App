# 📋 Architectural Decisions & Assumptions Log

## ADR-001: Money Representation
- **Decision**: All financial amounts are stored and calculated as **integer paise** (`BigInteger` or `Integer` where 1 INR = 100 paise).
- **Rationale**: Prevents floating point inaccuracy issues across database engines and programming languages. Presentation layers (Flutter frontend) will divide by 100 for display.

## ADR-002: Primary Keys and Metadata
- **Decision**: All database entities use **UUIDv4** as primary keys, with timestamp tracking (`created_at`, `updated_at` with timezones) and soft-delete capabilities (`is_deleted`).
- **Rationale**: Decouples ID generation from database sequence locks, prevents ID enumeration attacks, and supports safe data recovery.

## ADR-003: Storage Abstraction Layer
- **Decision**: Abstract `BaseStorageService` with `S3StorageService` implementation supporting MinIO (local dev) and S3/R2 (production).
- **Rationale**: Keeps business logic storage-agnostic and simplifies switching storage backends between development and production.

## ADR-004: Standard Error Envelope
- **Decision**: All non-2xx responses adhere to the standard shape:
  ```json
  {
    "error": {
      "code": "ERROR_CODE",
      "message": "Human-readable message",
      "details": {}
    }
  }
  ```
- **Rationale**: Provides predictable error consumption for Flutter mobile app clients and automated error reporting.

## ADR-005: Async Database Architecture
- **Decision**: SQLAlchemy 2.0 with `asyncpg` driver and async Alembic migrations.
- **Rationale**: Enables high-throughput concurrent I/O suitable for real-time mobile backend services.
