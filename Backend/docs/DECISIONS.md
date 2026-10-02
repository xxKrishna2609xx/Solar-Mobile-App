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

## ADR-006: Phone OTP Authentication & Refresh Token Rotation
- **Decision**: 
  - Mobile authentication via 6-digit OTPs hashed with HMAC-SHA256 in the database.
  - Rate limited to 3 OTP requests per phone number within a 10-minute sliding window.
  - Refresh tokens are hashed in the database and rotated on every `/auth/refresh` invocation.
  - In development (`ENV=dev`), `ConsoleSmsProvider` logs the OTP and respects `DEV_MOCK_OTP=123456`.
- **Rationale**: Eliminates passwords in mobile UX while maintaining cryptographic security against replay and token leakage.

## ADR-007: Mandatory Document Auto-Stage Progression
- **Decision**:
  - The required document set consists of: `e_bill`, `aadhaar`, `pan`, `cancelled_cheque`, and `registry`.
  - When all 5 mandatory document types are uploaded for a customer currently in `SALE_CONFIRMED`, the system automatically transitions the customer stage to `DOCUMENTS_RECEIVED` and logs a `StageHistory` entry.
  - Documents can only be deleted before the customer reaches `ADVANCE_VERIFIED`.
- **Rationale**: Automates workflow handoffs between sales and admin/finance teams without manual human intervention.

## ADR-008: Multi-Stage Payment Verification Workflow
- **Decision**:
  - Payment approval follows a 3-step state machine: `pending` (client submission) -> `sales_approved` (sales agent review) -> `verified` (admin/employer confirmation) or `rejected`.
  - When the first payment is verified and customer stage is `DOCUMENTS_RECEIVED`, the customer stage automatically advances to `ADVANCE_VERIFIED`.
  - Every status change logs an immutable entry into `payment_audit_logs`.
  - Row-level database locks (`SELECT FOR UPDATE`) are used during status transitions to prevent double approvals and race conditions.
  - Total non-rejected payments cannot exceed `customer.final_price`.
- **Rationale**: Guarantees financial accountability and auditability for customer billing.

## ADR-009: Work Assignment Validation & Automatic Installation Completion
- **Decision**:
  - Installation work is divided into three disciplines: `structure`, `electrical`, `civil`.
  - Work can only be assigned to a team whose `team.type` strictly matches the `work_type`.
  - Work assignment is blocked if customer stage is prior to `ADVANCE_VERIFIED` unless admin supplies `override=True`.
  - Completing a work assignment strictly requires at least 1 photo proof.
  - Starting work updates customer stage to `STRUCTURE_WORK`, `ELECTRICAL_WORK`, or `CIVIL_WORK`.
  - When all non-cancelled work assignments for a customer are completed, customer stage automatically progresses to `INSTALLATION_COMPLETE`.
- **Rationale**: Automates field operations tracking, enforces quality control through photo proof, and keeps project stage in sync with actual on-site progress.

## ADR-010: KEDL Discom Paperwork & Demand Management
- **Decision**:
  - Discom paperwork is divided into three discrete files per customer: `name_change`, `load`, and `net`.
  - Initializing KEDL files automatically advances the customer stage to `KEDL_PROCESS` (if in work/installation stage).
  - Raising a demand on a file automatically switches its status to `demand_raised`.
  - Resolving (paying/waiving) all open demands on a file automatically updates the file status to `demand_paid`.
  - Approving the `net` file automatically transitions the customer stage to `SYSTEM_LIVE`.
  - KEDL users are restricted to viewing and managing only files assigned to their user ID.
- **Rationale**: Accurately tracks discom bottlenecks, fee demands, and automatically detects when net metering goes live.

## ADR-011: Client Isolation & Post-Installation Service Tickets
- **Decision**:
  - All `/client/*` endpoints automatically infer customer scope from `current_user.id`, preventing cross-client data access.
  - The client home screen aggregates a 10-stage sequential timeline, responsible contacts (sales rep, active field lead, or KEDL agent), system specifications, and payment balances in a single optimized payload.
  - Service tickets are strictly available post-installation (`SYSTEM_LIVE` or `HANDED_OVER`).
  - Strict photo requirements are enforced per ticket type: `structure` requires 2-10 photos, `wiring` requires 1-10 photos, and `inverter` allows 0-10 photos (with optional inverter `error_code`).
  - Resolved tickets can only be reopened by customers within a strict **7-day window** of `resolved_at`.
- **Rationale**: Delivers a transparent, tamper-proof client self-service interface while preventing spurious post-installation tickets and stale re-openings.

