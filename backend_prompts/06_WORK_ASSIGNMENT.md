# 🏗️ STEP 06: Work Assignment (Structure / Electrical / Civil)

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Steps 02 to 04 must be complete.

## 🎯 Goal
Assign installation work to labour teams with dates, track progress, and collect completion photos.

## 🧾 Business Rules (from the owner's notes)
- Work is assigned **to customers with dates**.
- Three work types, each with its own set of teams (Team A, Team B, ... many options): **Structure**, **Electrical**, **Civil**.
- Work should normally be assigned after the advance payment is verified. **(CONFIRM: block or only warn?)** Default: block unless admin passes `override=true`.

## 📋 Tasks

### 1. Models + migration
**WorkAssignment**: `id, customer_id, work_type (structure|electrical|civil), team_id (FK Team, team.type must equal work_type), scheduled_start (date), scheduled_end (date), actual_start, actual_end, status (pending|in_progress|completed|cancelled), notes, assigned_by`

**WorkPhoto**: `id, work_assignment_id, file_key, caption, uploaded_by, created_at`

**WorkStatusLog**: `id, work_assignment_id, from_status, to_status, changed_by, created_at`

### 2. Endpoints
- `POST /api/v1/customers/{id}/work-assignments` (admin only)
  - Validate that `team.type == work_type` and `end >= start`
  - One active assignment per `(customer, work_type)`
  - Warn or return a conflict if the team already has an overlapping assignment on those dates (`allow_overlap` flag to bypass, because a team may handle more than one site a day) **(CONFIRM)**
- `GET /api/v1/work-assignments` filters: `work_type`, `team_id`, `status`, `date_from`, `date_to`, `customer_id`
  - `labour` sees only assignments for **their team**
- `GET /api/v1/work-assignments/{id}`
- `PATCH /api/v1/work-assignments/{id}` (admin: reschedule, change team, cancel)
- `POST /api/v1/work-assignments/{id}/start` (team member or admin)
- `POST /api/v1/work-assignments/{id}/complete` (team member or admin; **requires at least 1 photo**) **(CONFIRM)**
- `POST /api/v1/work-assignments/{id}/photos` multipart, up to 10 per request
- `GET /api/v1/work-assignments/calendar?from=&to=` returns a per-team schedule grouped by date for the app's calendar view

### 3. Logic
- Starting the first work of a type moves the customer stage: structure → `STRUCTURE_WORK`, electrical → `ELECTRICAL_WORK`, civil → `CIVIL_WORK`.
- When **all assigned work types** for a customer are completed, set the stage to `INSTALLATION_COMPLETE`.
- Write StageHistory entries for automatic stage changes (reuse the Step 04 service).
- `labour` users can see only the customer's **name, address, location and mobile** for assigned jobs, not prices or payments.
- Make the customer detail endpoint (Step 04) include work assignments for admin/sales.

### 4. Tests
- Team type mismatch rejected
- Labour from Team A cannot see Team B's jobs
- Completing requires a photo; stage transitions happen correctly
- Overlap detection and override

## ✅ Acceptance Checklist
- [ ] Admin can assign all three work types to different teams for one customer
- [ ] Labour sees only their team's jobs, with limited customer data
- [ ] Stage updates automatically through to `INSTALLATION_COMPLETE`
- [ ] Calendar endpoint returns grouped data
- [ ] Tests pass, migration applies cleanly
