# 🚢 STEP 10: Notifications, Reports, Hardening, Deployment

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. All previous steps must be complete.

## 🎯 Goal
Make the backend production-ready.

## 📋 Tasks

### 1. Push notifications (Firebase Cloud Messaging)
- `services/notifications.py` with a provider interface; `FcmProvider` and a `ConsoleProvider` for dev.
- `Notification` model: `id, user_id, title, body, data (JSONB), is_read, created_at`
- Endpoints: `GET /api/v1/notifications`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/read-all`, unread count
- Trigger notifications on:
  - client payment submitted → the salesperson
  - payment approved / verified / rejected → the client
  - work assigned → the team members
  - KEDL demand raised → the customer's salesperson and admin
  - stage changed → the client
  - ticket created → admin; ticket status changed or commented → the client
- Use FastAPI `BackgroundTasks` or a simple queue so API responses are not delayed. **(Celery/Redis only if needed)**

### 2. Reports (admin)
- `GET /api/v1/reports/dashboard`: leads by status, sales this month, pending payment verifications, active works, open KEDL demands, open tickets, low stock count
- `GET /api/v1/reports/sales` (by salesperson and period), `/payments` (collected vs pending), `/work` (by team), `/kedl`
- Export endpoints returning **Excel (.xlsx)** for customers, payments and inventory.

### 3. Audit and hardening
- Generic `AuditLog` for sensitive actions (user created, role changed, payment verified, stock adjusted)
- Rate limiting on auth endpoints, security headers, strict CORS, request size limits
- Input sanitization of filenames; never trust client MIME types alone
- Review all queries for N+1 problems (use `selectinload`/`joinedload`); add DB indexes for filters used in list endpoints
- Make sure `DEV_FIXED_OTP` and the console SMS provider **cannot** run when `ENV=prod`

### 4. Testing
- Run the full test suite with coverage; target ≥ 80% on services
- Add an end-to-end test: lead → convert → documents → payment → work → KEDL → live → ticket

### 5. Deployment
- Production `Dockerfile` (multi-stage), `docker-compose.prod.yml` with Nginx + HTTPS (Let's Encrypt/Caddy), Postgres with backups
- `.github/workflows/ci.yml`: lint, test, build image
- Guide in `docs/DEPLOY.md` for a small VPS or Render/Railway, including env variables, migrations on deploy, DB backup/restore, and log access
- Gunicorn with Uvicorn workers config

### 6. Handoff docs for the Flutter developer
- Export the OpenAPI spec to `docs/openapi.json`
- `docs/FLUTTER_INTEGRATION.md`: auth flow with token refresh, file upload examples, error format, pagination format, list of enums (stages, statuses, types)
- Postman/Insomnia collection (optional)

## ✅ Acceptance Checklist
- [ ] Notifications created for all listed events
- [ ] Reports return correct numbers; Excel exports open correctly
- [ ] The e2e test passes
- [ ] Production compose runs with HTTPS locally or on staging
- [ ] `docs/FLUTTER_INTEGRATION.md` and `openapi.json` are present
