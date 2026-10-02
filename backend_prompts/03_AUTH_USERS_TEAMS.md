# 🔐 STEP 03: Auth, Users, Roles, Teams

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Step 02 must be complete.

## 🎯 Goal
Phone-OTP login with JWT, role-based access, and management of employees and teams.

## 📋 Tasks

### 1. Models + migration
- `User`: `id, name, phone (unique, E.164 or 10-digit Indian), role (enum), team_id (nullable FK), is_active, is_deleted, fcm_token (nullable), last_login_at`
- `Team`: `id, name, type (structure|electrical|civil)`; unique on `(type, name)`
- `OtpCode`: `id, phone, code_hash, expires_at, attempts, consumed_at`
- `RefreshToken`: `id, user_id, token_hash, expires_at, revoked_at, device_info`

### 2. OTP login flow
- `POST /api/v1/auth/request-otp` `{phone}`
  - Only phones that exist as active users may log in (admin creates users; clients are created when a customer is created). Return a generic response either way to avoid user enumeration.
  - Rate limit: max 3 OTPs per phone per 10 minutes.
- `POST /api/v1/auth/verify-otp` `{phone, otp}` → `{access_token, refresh_token, user}`
  - OTP: 6 digits, 5-minute expiry, max 5 attempts, stored **hashed**.
- `POST /api/v1/auth/refresh` → rotates the refresh token
- `POST /api/v1/auth/logout` → revokes the refresh token
- `GET /api/v1/auth/me`
- `PUT /api/v1/auth/me/fcm-token`

### 3. SMS provider abstraction
- `services/sms/base.py` with `send_otp(phone, code)`.
- `ConsoleSmsProvider` (prints OTP in logs, **dev only**) and a placeholder `Msg91SmsProvider` class (not implemented, just the interface). **(CONFIRM provider)**
- In dev, allow a fixed OTP via env `DEV_FIXED_OTP=123456` (must be disabled when `ENV=prod`).

### 4. Authorization
- `get_current_user` dependency (validates JWT, loads active user)
- `require_roles(*roles)` dependency
- Make sure deactivated users are rejected immediately.

### 5. Users and employees (admin only)
- `POST /api/v1/users` create employee (role in `sales|labour|kedl|admin`; `labour` requires `team_id`)
- `GET /api/v1/users` list with filters: `role`, `team_id`, `is_active`, `search` (name or phone), paginated
- `GET /api/v1/users/{id}`, `PATCH /api/v1/users/{id}`, `DELETE /api/v1/users/{id}` (soft delete / deactivate)

### 6. Teams (admin only for write, authenticated for read)
- CRUD under `/api/v1/teams`; `GET /api/v1/teams?type=structure`
- A team cannot be deleted while it has active members or open work assignments (the assignments check can be a stub until Step 06).

### 7. Seed
- A CLI command `python -m app.cli create-admin --name --phone` to create the first admin.
- A seed command for sample teams: Structure A/B, Electrical A/B, Civil A/B.

### 8. Tests
- OTP success, wrong OTP, expired OTP, attempts exceeded, rate limit
- Role access: each role against each user-management endpoint (allowed and forbidden)
- Refresh rotation and revoked tokens

## 🚫 Do Not
- Do not store OTPs or refresh tokens in plain text.
- Do not allow self-registration with a role.
- Do not build customers or leads yet.

## ✅ Acceptance Checklist
- [ ] Admin can be created via CLI and can log in using the dev OTP
- [ ] Admin can create sales, labour (with team), and kedl users
- [ ] A `sales` user gets **403** on `POST /users`
- [ ] Refresh and logout work; revoked token is rejected
- [ ] All tests pass, migration applies on an empty DB
