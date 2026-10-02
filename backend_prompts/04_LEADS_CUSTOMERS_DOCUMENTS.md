# 👥 STEP 04: Leads, Customers, Documents

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Steps 02 and 03 must be complete.

## 🎯 Goal
Sales workflow: assign salespeople → manage leads → close sale → store full customer data and documents.

## 📋 Tasks

### 1. Models + migration
**Lead**: `id, name, phone, area/address, expected_kw (nullable), source, status (new|contacted|follow_up|converted|lost), follow_up_date, notes, assigned_sales_id (FK User), customer_id (nullable, set on conversion), lost_reason`

**Customer**:
`id, name, mobile (unique), address, latitude, longitude, sales_id (FK User), user_id (FK User with role client), final_price, capacity_kw, phase (single|three), panel_brand, panel_watt, panel_count, inverter_brand, structure_type, stage (Customer Stage Enum, default SALE_CONFIRMED), sale_closed_at, is_deleted`

**CustomerDocument**: `id, customer_id, type (e_bill|aadhaar|pan|cancelled_cheque|registry|other), file_key, original_name, mime_type, size_bytes, uploaded_by`

**StageHistory**: `id, customer_id, from_stage, to_stage, changed_by, note, created_at`

### 2. Lead management endpoints
- `POST /api/v1/leads` (admin, sales). A sales user creates leads assigned to themselves; admin can assign to anyone.
- `GET /api/v1/leads` filters: `status`, `assigned_sales_id`, `search`, date range. **Sales sees only their own leads**; admin sees all.
- `PATCH /api/v1/leads/{id}`; `POST /api/v1/leads/{id}/assign` (admin only, reassign salesperson)
- `POST /api/v1/leads/{id}/convert` → creates a **Customer** + a `client` User (using the mobile number), sets lead to `converted`, links both. Must be one DB transaction. Fails if the mobile already belongs to a customer.
- `POST /api/v1/leads/{id}/mark-lost` with a reason

### 3. Customer endpoints (**Sales Closed**)
- `POST /api/v1/customers` (direct creation without a lead is allowed)
- `GET /api/v1/customers` filters: `stage`, `sales_id`, `search`, paginated. Sales sees only own customers; admin sees all; labour/kedl see only customers they are assigned to (can be a stub until Steps 06 and 07).
- `GET /api/v1/customers/{id}` returns the full record with documents count and payment summary placeholder
- `PATCH /api/v1/customers/{id}`
- `PATCH /api/v1/customers/{id}/stage` (admin only; validates allowed transitions and writes StageHistory)
- Validation: mobile format, latitude/longitude range (the GPS values come from the app's "current location" button), `final_price >= 0`.

### 4. Documents (using the storage abstraction from Step 02)
- `POST /api/v1/customers/{id}/documents` multipart upload with `type`
  - Allowed: jpg, png, pdf. Max 10 MB. Validate by MIME type and extension.
  - Store under `customers/{customer_id}/{type}/{uuid}.{ext}`
- `GET /api/v1/customers/{id}/documents` returns metadata with **short-lived presigned URLs**
- `DELETE /api/v1/documents/{id}` (admin, or the uploader while the stage is before `ADVANCE_VERIFIED`)
- When all required documents (e_bill, aadhaar, pan, cancelled_cheque, registry) exist, auto-move the stage from `SALE_CONFIRMED` to `DOCUMENTS_RECEIVED`. **(CONFIRM the required set)**

### 5. Tests
- Convert lead creates customer + client user atomically
- A sales user cannot read another salesperson's leads or customers
- A client user can read only their own customer
- Upload validation (bad type, too big), presigned URL works, auto stage change

## 🚫 Do Not
- Do not build payments yet (only leave the `payment summary` as a placeholder field).
- Do not return raw storage keys to the client, return presigned URLs.

## ✅ Acceptance Checklist
- [ ] Lead → convert → customer + client user created
- [ ] Documents upload to MinIO and download via presigned URL
- [ ] Stage history is recorded
- [ ] Row-level access rules are tested
- [ ] Tests pass, new migration applies cleanly
