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

### Request OTP
- **Endpoint**: `POST /api/v1/auth/request-otp`
- **Body**: `{"phone": "9876543210"}`
- **Response**: `{"message": "If the mobile number is registered, an OTP has been dispatched."}`

### Verify OTP
- **Endpoint**: `POST /api/v1/auth/verify-otp`
- **Body**: `{"phone": "9876543210", "otp": "123456", "device_info": "Pixel 7"}`
- **Response**:
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "a1b2c3d4...",
  "token_type": "bearer",
  "user": {
    "id": "c1f7b8d2-...",
    "name": "Ravi Kumar",
    "phone": "9876543210",
    "role": "sales",
    "team_id": null,
    "team": null,
    "is_active": true,
    "fcm_token": null,
    "last_login_at": "2026-10-02T10:00:00Z",
    "created_at": "2026-10-02T09:00:00Z",
    "updated_at": "2026-10-02T10:00:00Z"
  }
}
```

### Refresh Token (Rotation)
- **Endpoint**: `POST /api/v1/auth/refresh`
- **Body**: `{"refresh_token": "a1b2c3d4..."}`
- **Response**: New access & refresh token pair.

### Logout
- **Endpoint**: `POST /api/v1/auth/logout`
- **Body**: `{"refresh_token": "a1b2c3d4..."}`
- **Response**: `{"message": "Logged out successfully."}`

### Current User Profile
- **Endpoint**: `GET /api/v1/auth/me`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response**: User object.

### Update FCM Token
- **Endpoint**: `PUT /api/v1/auth/me/fcm-token`
- **Headers**: `Authorization: Bearer <access_token>`
- **Body**: `{"fcm_token": "fcm_token_string..."}`
- **Response**: Updated user object.

---

## 3. Users & Employees Management (`/api/v1/users`) *(Admin Only)*

- `POST /api/v1/users` - Create employee (`sales`, `labour`, `kedl`, `admin`). Note: `labour` role requires `team_id`.
- `GET /api/v1/users` - List users with query params `page`, `page_size`, `role`, `team_id`, `is_active`, `search`.
- `GET /api/v1/users/{id}` - Get user details.
- `PATCH /api/v1/users/{id}` - Update user details.
- `DELETE /api/v1/users/{id}` - Soft-delete & deactivate user.

---

## 4. Teams Management (`/api/v1/teams`)

- `POST /api/v1/teams` *(Admin Only)* - Create team (`name`, `type`: `structure` | `electrical` | `civil`).
- `GET /api/v1/teams` *(Authenticated)* - List teams (optional filter `?type=structure`).
- `GET /api/v1/teams/{id}` *(Authenticated)* - Get team details.
- `PATCH /api/v1/teams/{id}` *(Admin Only)* - Update team name/type.
- `DELETE /api/v1/teams/{id}` *(Admin Only)* - Delete team (fails if active members exist).

---

## 5. Management CLI Commands

```bash
# Create or update an admin user
python -m app.cli create-admin --name "Super Admin" --phone "9876543210"

# Seed default teams
python -m app.cli seed-teams
```
