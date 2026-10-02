# 🧭 MASTER CONTEXT (Project Rules for the Agent)

> Keep this file in the workspace. Every later task follows it.

## 1. Project
Backend API for a **mobile app (Flutter, Android + iOS)** used by a **solar rooftop installation and selling business in India**.

Lifecycle: `Lead → Sale Closed → Payments → Work (Structure / Electrical / Civil) → KEDL paperwork (Name Change, Load, Net file) → Net metering → Live → Service tickets`.

KEDL = the local electricity distribution company. A **"Demand"** on a KEDL file is a pending requirement raised by KEDL (amount/document). **(CONFIRM)**

## 2. Tech Stack (fixed)
- Python 3.12, **FastAPI**, Pydantic v2, pydantic-settings
- **PostgreSQL 16**, SQLAlchemy 2.0 (**async**, asyncpg), **Alembic**
- Auth: phone OTP → JWT (access + refresh), role-based access
- Files: S3-compatible storage (**MinIO locally**, S3/R2 in production) via `boto3`/`aioboto3`
- Tests: pytest, pytest-asyncio, httpx
- Lint/format: ruff. Typing everywhere.
- Docker + docker-compose for local development
- Package manager: `uv` or `pip` with `requirements.txt` (pick one and stay consistent)

## 3. Roles
`admin` (employer), `sales`, `labour`, `kedl`, `client`.
- `labour` users belong to a **Team** with type `structure | electrical | civil` and a name (Team A, Team B, ...).
- `client` users are customers who log in with their mobile number.

## 4. Customer Stage Enum (single source of truth)
```
SALE_CONFIRMED → DOCUMENTS_RECEIVED → ADVANCE_VERIFIED → STRUCTURE_WORK →
ELECTRICAL_WORK → CIVIL_WORK → INSTALLATION_COMPLETE → KEDL_PROCESS →
SYSTEM_LIVE → HANDED_OVER
```

## 5. Architecture Rules
```
app/
├── main.py
├── core/          # config, security, deps, exceptions, logging
├── db/            # base, session, migrations helpers
├── models/        # SQLAlchemy models (one file per entity)
├── schemas/       # Pydantic schemas (Create/Update/Read)
├── api/v1/        # routers only (thin)
├── services/      # business logic (thick)
├── storage/       # file storage abstraction
└── tests/
```
- Routers stay thin. **Business rules live in `services/`**.
- All primary keys are **UUID**. Every table has `created_at`, `updated_at`. Use soft delete (`is_deleted`) where data matters (customers, payments).
- Money is stored as **integer paise** or `Numeric(12,2)`, never float. **(CONFIRM which)**
- All list endpoints are **paginated** (`page`, `page_size`) and filterable.
- All endpoints are under `/api/v1`. Use clear tags for Swagger.
- Standard error format: `{"error": {"code": "...", "message": "...", "details": {...}}}`
- Role checks via reusable dependencies, e.g. `require_roles("admin", "sales")`.
- A `client` can **only ever access their own customer record**. Enforce this in services, not only in routers.
- Never trust the client for `role`, `user_id` or approval status.
- Secrets only in environment variables. Provide `.env.example`.
- Every migration is generated with Alembic. Never edit the DB by hand.
- Every feature ships with **tests** and a short section in `docs/`.

## 6. Working Style for the Agent
1. **Plan first.** Show a short implementation plan and the files you will create or change.
2. Build in small steps. Run the app and the tests yourself.
3. Do **not** add features that are not in the current task.
4. If something is unclear, make the most reasonable choice, write it under "Assumptions" in `docs/DECISIONS.md`, and continue.
5. At the end, give a summary: what was built, how to run it, how to test it.
6. Keep the code readable. Short functions, docstrings on services.

## 7. Definition of Done (every step)
- [ ] App starts with `docker compose up`
- [ ] Migrations apply cleanly on an empty database
- [ ] New endpoints appear in `/docs` with correct schemas
- [ ] Role permissions tested (allowed and forbidden cases)
- [ ] `pytest` passes, `ruff check` is clean
- [ ] `docs/DECISIONS.md` and `docs/API.md` updated
