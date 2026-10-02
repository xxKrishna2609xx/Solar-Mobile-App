# 📱 Flutter Mobile App Integration Guide

Welcome to the backend API reference for the Solar Rooftop Flutter client. This document outlines core architectural patterns, token lifecycles, error handling conventions, multipart upload protocols, and stage mapping.

---

## 1. Authentication Flow & Token Lifecycle

### Step 1: Request Login OTP
- **Endpoint**: `POST /api/v1/auth/otp/request`
- **Body**: `{"phone": "9876543210"}`
- **Response**:
  ```json
  {
    "message": "OTP sent successfully.",
    "expires_in_seconds": 300,
    "resend_available_in_seconds": 30
  }
  ```

### Step 2: Verify OTP
- **Endpoint**: `POST /api/v1/auth/otp/verify`
- **Body**: `{"phone": "9876543210", "code": "123456"}`
- **Response**:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid-here",
      "phone": "9876543210",
      "name": "Sunita Sharma",
      "role": "client"
    }
  }
  ```

### Step 3: Refresh Expired Access Token
When an API call returns `401 Unauthorized`:
- **Endpoint**: `POST /api/v1/auth/token/refresh`
- **Body**: `{"refresh_token": "<stored_refresh_token>"}`
- **Response**: New access and rotated refresh token pair.

---

## 2. Standard Error Format

All API errors return HTTP 4xx/5xx status codes with a consistent JSON envelope:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Structure tickets require between 2 and 10 photos.",
    "details": null
  }
}
```

Common Error Codes:
- `UNAUTHORIZED`: Invalid or expired JWT token.
- `FORBIDDEN`: User role does not have permission for the endpoint.
- `NOT_FOUND`: Resource with given ID does not exist.
- `VALIDATION_ERROR`: Field constraints violated (e.g. invalid photo count, negative amount).
- `CONFLICT`: Duplicate record (e.g. phone number or serial number already registered).
- `RATE_LIMITED`: Too many OTP requests within cooldown window.

---

## 3. Client Mobile Home Dashboard

- **Endpoint**: `GET /api/v1/client/home`
- **Headers**: `Authorization: Bearer <access_token>`
- **Response Shape**:
  ```json
  {
    "customer": { ... },
    "stage": "structure_work",
    "timeline": [
      {"stage": "sale_confirmed", "title": "Sale Confirmed", "status": "done", "date": "2026-10-01T10:00:00Z"},
      {"stage": "documents_received", "title": "Documents Received", "status": "done", "date": "2026-10-01T12:00:00Z"},
      {"stage": "advance_verified", "title": "Advance Payment Verified", "status": "done", "date": "2026-10-01T15:00:00Z"},
      {"stage": "structure_work", "title": "Structure Installation", "status": "current", "date": null},
      {"stage": "electrical_work", "title": "Electrical Wiring & Inverter", "status": "upcoming", "date": null},
      {"stage": "civil_work", "title": "Civil Works", "status": "upcoming", "date": null},
      {"stage": "installation_complete", "title": "Installation Complete", "status": "upcoming", "date": null},
      {"stage": "kedl_process", "title": "KEDL Discom Paperwork", "status": "upcoming", "date": null},
      {"stage": "system_live", "title": "System Live & Net Metering", "status": "upcoming", "date": null},
      {"stage": "handed_over", "title": "Project Handed Over", "status": "upcoming", "date": null}
    ],
    "responsible_contact": {
      "name": "Structure Alpha Lead",
      "phone": "9829011111",
      "role_title": "Structure Installation Team"
    },
    "sales_contact": {
      "name": "Rajesh Sharma",
      "phone": "9829000000",
      "role_title": "Sales Executive"
    },
    "payment_summary": {
      "final_price": 25000000,
      "total_paid": 5000000,
      "balance_due": 20000000,
      "advance_amount": 5000000,
      "advance_status": "verified"
    },
    "system_specs": {
      "capacity_kw": 5.0,
      "phase": "single",
      "panel_brand": "Tata Power Solar",
      "panel_watt": 540,
      "panel_count": 10,
      "inverter_brand": "Havells",
      "structure_type": "Elevated GI"
    }
  }
  ```

> [!NOTE]
> All financial amounts are represented in **paise** as 64-bit integers.
> To display in INR: `display_inr = (amount_in_paise / 100).toStringAsFixed(2);`

---

## 4. Post-Installation Service Tickets

- **Create Ticket**: `POST /api/v1/client/tickets`
- **Validation Rules**:
  - `type: "structure"`: requires `2` to `10` uploaded photo keys in `image_keys`.
  - `type: "wiring"`: requires `1` to `10` uploaded photo keys in `image_keys`.
  - `type: "inverter"`: accepts `0` to `10` photo keys and accepts optional `error_code`.
- **Reopen Ticket**: `POST /api/v1/client/tickets/{id}/reopen`
  - Reopening is permitted strictly within **7 days** of ticket resolution.

---

## 5. Push Notifications (FCM)

1. On login or app start, obtain FCM device token from Firebase SDK.
2. Send to backend: `POST /api/v1/auth/fcm-token` with body `{"fcm_token": "<fcm_token_string>"}`.
3. Badge count: Call `GET /api/v1/notifications/unread-count`.
4. In-App Notifications List: Call `GET /api/v1/notifications`.
