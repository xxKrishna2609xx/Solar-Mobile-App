# 🙋 STEP 08: Client App APIs and Service Tickets

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Steps 02 to 07 must be complete.

## 🎯 Goal
Everything the **customer login** needs: project status, payments, and service tickets.

## 🧾 Client Features (from the owner's notes)
1. **Status with employee number** (who to call)
2. **Payment submit with photo**, approved by salesman (already built in Step 05, expose it cleanly here)
3. **Raise service ticket**:
   - **Structure issue** + upload images (**2 to 10**)
   - **Wiring issue** + photo upload
   - **Inverter fault**

## 📋 Tasks

### 1. Models + migration
**ServiceTicket**: `id, ticket_no (human-friendly, e.g. TCK-000123), customer_id, type (structure|wiring|inverter), title, description, status (open|assigned|in_progress|resolved|closed|reopened), priority (low|normal|high), assigned_to (FK User, nullable), resolved_at, resolution_note, created_by`

**TicketImage**: `id, ticket_id, file_key, uploaded_by`

**TicketComment**: `id, ticket_id, author_id, message, created_at`

**TicketStatusLog**: `id, ticket_id, from_status, to_status, changed_by, created_at`

### 2. Client endpoints (`client` role only, always scoped to their own customer)
- `GET /api/v1/client/home` returns:
  - current stage, a full ordered timeline (all 10 stages with `done|current|upcoming` and dates from StageHistory)
  - contact: the **assigned salesperson** and the **current responsible employee** (name + phone) based on the stage (sales before work, team lead during work, KEDL employee during KEDL process) **(CONFIRM mapping)**
  - payment summary: final price, paid (verified), pending, balance
  - system details: kW, panels, inverter
- `GET /api/v1/client/payments`, `POST /api/v1/client/payments` (wraps the Step 05 service, multipart with the proof photo)
- `GET /api/v1/client/documents`

### 3. Tickets
- `POST /api/v1/client/tickets` multipart:
  - `structure`: **2 to 10 images required**
  - `wiring`: 1 to 10 images required
  - `inverter`: images optional; optional `error_code`
  - Validate image count, type (jpg/png) and size (max 10 MB each)
- `GET /api/v1/client/tickets`, `GET /api/v1/client/tickets/{id}`
- `POST /api/v1/client/tickets/{id}/comments`, `POST /api/v1/client/tickets/{id}/reopen` (only when resolved, within 7 days)
- Staff side:
  - `GET /api/v1/tickets` filters: `status`, `type`, `assigned_to`, `customer_id`, `priority`
  - `POST /api/v1/tickets/{id}/assign` (admin)
  - `POST /api/v1/tickets/{id}/status` (admin or assignee; resolving needs a note)
  - `POST /api/v1/tickets/{id}/comments`
- Block new tickets for customers whose stage is before `SYSTEM_LIVE`. **(CONFIRM)**

### 4. Tests
- A client cannot read another client's data (try IDs directly)
- Image count rules per ticket type
- Timeline is correct for different stages
- Reopen window enforcement

## ✅ Acceptance Checklist
- [ ] `/client/home` gives the Flutter app everything for the status screen in one call
- [ ] All three ticket types work with their image rules
- [ ] Staff can assign, comment, resolve
- [ ] Tests pass, migration applies cleanly
