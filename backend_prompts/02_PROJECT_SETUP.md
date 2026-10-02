# 🛠️ STEP 02: Project Setup

> Read `RULES.md` / `01_MASTER_CONTEXT.md` first and follow it strictly.

## 🎯 Goal
Create the FastAPI project skeleton so later steps only add features.

## 📋 Tasks
1. Create the folder structure from the master context.
2. Create `docker-compose.yml` with services:
   - `api` (FastAPI with hot reload)
   - `db` (PostgreSQL 16 with a volume)
   - `minio` (S3-compatible storage) plus an init step that creates a bucket
3. Create a `Dockerfile` (python:3.12-slim, non-root user).
4. Create `core/config.py` using `pydantic-settings`: DB URL, JWT secret, token lifetimes, OTP settings, storage settings, `ENV` (`dev|prod`), CORS origins.
5. Create `.env.example` with every variable and safe dev defaults.
6. Set up the async SQLAlchemy engine/session (`db/session.py`) and the declarative `Base` with a mixin for `id (UUID)`, `created_at`, `updated_at`.
7. Set up **Alembic** (async-compatible) and generate an empty initial migration.
8. Create `main.py` with:
   - app factory, CORS, request-ID middleware, structured logging
   - global exception handlers returning the standard error format
   - `GET /api/v1/health` (checks DB connectivity)
9. Create the storage abstraction `storage/base.py` (`upload`, `delete`, `get_presigned_url`) and a MinIO/S3 implementation. Do not use it yet.
10. Add tooling: `pyproject.toml` (ruff config), `Makefile` with `up`, `down`, `migrate`, `revision`, `test`, `lint`.
11. Add pytest setup with a **separate test database** and fixtures (`client`, `db_session`).
12. Add `.gitignore`, `README.md` (how to run), `docs/DECISIONS.md`, `docs/API.md`.

## 🚫 Do Not
- Do not create business models yet (users, customers, etc.).
- Do not hardcode secrets.

## ✅ Acceptance Checklist
- [ ] `docker compose up` starts api, db and minio with no errors
- [ ] `GET /api/v1/health` returns `{"status": "ok", "db": "ok"}`
- [ ] `make migrate` and `make test` work
- [ ] A test for the health endpoint passes
- [ ] Swagger opens at `/docs`
