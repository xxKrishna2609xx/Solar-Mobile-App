# 🔌 API Documentation

## Base URLs
- Local Development: `http://localhost:8000/api/v1`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI JSON: `http://localhost:8000/openapi.json`

---

## 1. System Health
- `GET /api/v1/health` - Check API and DB status.

---

## 2. Authentication & Profile (`/api/v1/auth`)

- `POST /api/v1/auth/request-otp` - Request 6-digit OTP.
- `POST /api/v1/auth/verify-otp` - Verify OTP and receive JWT access + refresh tokens.
- `POST /api/v1/auth/refresh` - Rotate refresh token.
- `POST /api/v1/auth/logout` - Revoke refresh token.
- `GET /api/v1/auth/me` - Authenticated user profile.
- `PUT /api/v1/auth/me/fcm-token` - Update FCM push notification token.

---

## 3. Users & Employees (`/api/v1/users`) *(Admin Only)*

- `POST /api/v1/users` - Create employee (`sales`, `labour`, `kedl`, `admin`).
- `GET /api/v1/users` - List users (`role`, `team_id`, `is_active`, `search`, paginated).
- `GET /api/v1/users/{id}` - Get user details.
- `PATCH /api/v1/users/{id}` - Update user.
- `DELETE /api/v1/users/{id}` - Soft-delete & deactivate user.

---

## 4. Teams (`/api/v1/teams`)

- `POST /api/v1/teams` *(Admin Only)* - Create team (`name`, `type`: `structure` | `electrical` | `civil`).
- `GET /api/v1/teams` *(Authenticated)* - List teams (optional filter `?type=structure`).
- `GET /api/v1/teams/{id}` *(Authenticated)* - Get team details.
- `PATCH /api/v1/teams/{id}` *(Admin Only)* - Update team.
- `DELETE /api/v1/teams/{id}` *(Admin Only)* - Delete team.

---

## 5. Leads Management (`/api/v1/leads`)

- `POST /api/v1/leads` - Create lead (Sales creates for self; Admin can assign).
- `GET /api/v1/leads` - List leads with filters (`status`, `assigned_sales_id`, `search`, `start_date`, `end_date`). Sales only sees own leads.
- `GET /api/v1/leads/{id}` - Get lead details.
- `PATCH /api/v1/leads/{id}` - Update lead.
- `POST /api/v1/leads/{id}/assign` *(Admin Only)* - Reassign lead to another salesperson.
- `POST /api/v1/leads/{id}/mark-lost` - Mark lead as lost with `reason`.
- `POST /api/v1/leads/{id}/convert` - Atomically convert lead into Customer + client User (`SALE_CONFIRMED`).

---

## 6. Customers Management (`/api/v1/customers`)

- `POST /api/v1/customers` - Directly create a customer (Sale closed).
- `GET /api/v1/customers` - List customers (`stage`, `sales_id`, `search`, paginated). Row-level isolation enforced.
- `GET /api/v1/customers/{id}` - Get full customer details with `documents_count`, `stage_histories`, and `payment_summary`.
- `PATCH /api/v1/customers/{id}` - Update customer details.
- `PATCH /api/v1/customers/{id}/stage` *(Admin Only)* - Validated stage transition with `StageHistory` recording.
- `POST /api/v1/customers/{id}/documents` - Multipart document upload (auto-advances to `DOCUMENTS_RECEIVED` once all 5 required docs exist).
- `GET /api/v1/customers/{id}/documents` - List customer documents with presigned download URLs.

---

## 7. Documents (`/api/v1/documents`)

- `DELETE /api/v1/documents/{id}` - Delete document (Admin or uploader before `ADVANCE_VERIFIED` stage).
