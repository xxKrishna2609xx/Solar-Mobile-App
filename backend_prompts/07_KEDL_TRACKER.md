# 🗂️ STEP 07: KEDL Tracker (Name Change / Load / Net File)

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Steps 02 to 04 must be complete.

## 🎯 Goal
A dedicated KEDL employee tracks three discom files per customer after work is assigned, along with each file's **Demand**.

## 🧾 Business Rules (from the owner's notes)
- After work is assigned, three files are tracked: **Name Change file**, **Load file**, **Net file**.
- Each file has a **Demand** (pending requirement raised by KEDL: an amount and/or document request). **(CONFIRM the meaning)**
- Handled by employees with role `kedl`.

## 📋 Tasks

### 1. Models + migration
**KedlFile**: `id, customer_id, file_type (name_change|load|net), status (not_started|submitted|demand_raised|demand_paid|approved|rejected), application_no, submitted_on, approved_on, assigned_to (FK User role kedl), remarks, is_deleted`; unique on `(customer_id, file_type)`

**KedlDemand**: `id, kedl_file_id, description, amount (nullable), due_date, status (open|paid|waived), paid_on, receipt_key, raised_on, raised_by`

**KedlDocument**: `id, kedl_file_id, doc_type, file_key, original_name, uploaded_by`

**KedlStatusLog**: `id, kedl_file_id, from_status, to_status, changed_by, note, created_at`

### 2. Endpoints
- `POST /api/v1/customers/{id}/kedl-files/init` (admin) creates the three files in `not_started` and assigns a KEDL employee (`assigned_to` optional).
- `GET /api/v1/kedl-files` filters: `file_type`, `status`, `assigned_to`, `has_open_demand`, `customer_id`, `search`; `kedl` sees only their assigned files
- `GET /api/v1/kedl-files/{id}` includes demands, documents and the status log
- `PATCH /api/v1/kedl-files/{id}` (assignee/admin: application_no, remarks)
- `POST /api/v1/kedl-files/{id}/status` `{status, note}` validates allowed transitions
- `POST /api/v1/kedl-files/{id}/demands` raise a demand (sets status `demand_raised`)
- `PATCH /api/v1/kedl-demands/{id}` mark paid/waived (upload a receipt); when no open demand remains, file status becomes `demand_paid`
- `POST /api/v1/kedl-files/{id}/documents` upload (jpg/png/pdf, max 10 MB)
- `GET /api/v1/kedl/dashboard` counts by file type and status, plus the number of open demands and overdue demands

### 3. Logic
- When KEDL files are initialised, move the customer stage to `KEDL_PROCESS` (if the stage is `INSTALLATION_COMPLETE` or later in work). **(CONFIRM: can KEDL start while installation is still in progress? Default: allowed after work is assigned.)**
- When the **Net file** is `approved`, move the customer stage to `SYSTEM_LIVE`.
- Overdue demand = `due_date < today` and `status = open`.

### 4. Tests
- Init creates exactly three files; duplicates blocked
- Demand flow changes statuses correctly
- A kedl user cannot see files assigned to others
- Stage auto-moves on Net approval

## ✅ Acceptance Checklist
- [ ] Three files per customer, each with demands, documents and history
- [ ] Dashboard counts are correct
- [ ] Access limited by assignment
- [ ] Tests pass, migration applies cleanly
