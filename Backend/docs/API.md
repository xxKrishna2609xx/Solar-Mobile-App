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
- `GET /api/v1/customers/{id}` - Get full customer details with `documents_count`, `stage_histories`, and live `payment_summary`.
- `PATCH /api/v1/customers/{id}` - Update customer details.
- `PATCH /api/v1/customers/{id}/stage` *(Admin Only)* - Validated stage transition with `StageHistory` recording.
- `POST /api/v1/customers/{id}/documents` - Multipart document upload (auto-advances to `DOCUMENTS_RECEIVED` once all 5 required docs exist).
- `GET /api/v1/customers/{id}/documents` - List customer documents with presigned download URLs.

---

## 7. Documents (`/api/v1/documents`)

- `DELETE /api/v1/documents/{id}` - Delete document (Admin or uploader before `ADVANCE_VERIFIED` stage).

---

## 8. Payments Management (`/api/v1/payments`)

- `POST /api/v1/customers/{customer_id}/payments` - Record/submit payment (multipart with proof image).
- `GET /api/v1/customers/{customer_id}/payments` - List customer payments with total verified, pending, and balance summary.
- `GET /api/v1/payments/pending` - Pending payments approval queue (Sales queue for own customers; Admin queue for verification).
- `POST /api/v1/payments/{payment_id}/sales-approve` - Sales agent approves pending payment (`sales_approved`).
- `POST /api/v1/payments/{payment_id}/verify` *(Admin Only)* - Admin verifies received payment (`verified`). Auto-advances customer stage to `ADVANCE_VERIFIED` on first verified payment.
- `POST /api/v1/payments/{payment_id}/reject` - Reject payment with required `reason`.
- `PATCH /api/v1/payments/{payment_id}` - Update payment details (only while `pending`).

---

## 9. Work Assignments (`/api/v1/work-assignments`)

- `POST /api/v1/customers/{customer_id}/work-assignments` *(Admin Only)* - Assign structure/electrical/civil work to a team with dates.
- `GET /api/v1/work-assignments` - List work assignments with filters (`customer_id`, `team_id`, `work_type`, `status`, `date_from`, `date_to`). Labour is scoped to their own team.
- `GET /api/v1/work-assignments/{assignment_id}` - Get assignment details.
- `PATCH /api/v1/work-assignments/{assignment_id}` *(Admin Only)* - Update dates, team, notes, or cancel.
- `POST /api/v1/work-assignments/{assignment_id}/start` - Mark work started (transitions customer stage to `STRUCTURE_WORK`/`ELECTRICAL_WORK`/`CIVIL_WORK`).
- `POST /api/v1/work-assignments/{assignment_id}/photos` - Upload proof/progress photos (multipart, up to 10 photos).
- `POST /api/v1/work-assignments/{assignment_id}/complete` - Mark work completed (requires >=1 photo; auto-advances customer to `INSTALLATION_COMPLETE` when all assigned works are done).
- `GET /api/v1/work-assignments/calendar` - Calendar schedules grouped by date (`by_date`) and team (`by_team`).

---

## 10. KEDL Paperwork Tracker (`/api/v1/kedl-files`)

- `POST /api/v1/customers/{customer_id}/kedl-files/init` - Initialize Name Change, Load, and Net files for customer.
- `GET /api/v1/kedl-files` - List KEDL files with filters (`file_type`, `status`, `assigned_to`, `has_open_demand`, `customer_id`, `search`).
- `GET /api/v1/kedl/dashboard` - Dashboard metrics with file counts, open demands, and overdue demands.
- `GET /api/v1/kedl-files/{file_id}` - Get file details with demands, documents, and status logs.
- `PATCH /api/v1/kedl-files/{file_id}` - Update application number, remarks, or assignee.
- `POST /api/v1/kedl-files/{file_id}/status` - Update file status (approving Net file auto-advances customer stage to `SYSTEM_LIVE`).
- `POST /api/v1/kedl-files/{file_id}/demands` - Raise a demand requirement on a file (auto-sets status `demand_raised`).
- `PATCH /api/v1/kedl-demands/{demand_id}` - Mark demand paid/waived with optional receipt (when all demands resolved, auto-sets status `demand_paid`).
- `POST /api/v1/kedl-files/{file_id}/documents` - Upload KEDL paperwork document.

## Client Experience Endpoints (`/api/v1/client`)
- `GET /api/v1/client/home` - Aggregated client home dashboard with 10-stage timeline, contacts, system specs, and financial balance.
- `GET /api/v1/client/payments` - Client view of payments, balance, and next installment amount.
- `POST /api/v1/client/payments` - Client submits payment transaction with proof receipt.
- `GET /api/v1/client/documents` - List client KYC and solar project documents with presigned URLs.
- `POST /api/v1/client/tickets` - Raise a post-installation service ticket with issue-type image validation.
- `GET /api/v1/client/tickets` - List all tickets for current client.
- `GET /api/v1/client/tickets/{id}` - View ticket detail, status log history, and conversation comments.
- `POST /api/v1/client/tickets/{id}/comments` - Add message/comment to ticket.
- `POST /api/v1/client/tickets/{id}/reopen` - Reopen a resolved ticket within 7 days.

## Staff Service Ticket Management (`/api/v1/tickets`)
- `GET /api/v1/tickets` - List tickets across customers with filters for `status`, `type`, and `assigned_to`.
- `GET /api/v1/tickets/{id}` - Ticket detail view with full comment threads and status logs.
- `POST /api/v1/tickets/{id}/assign` - Assign service ticket to a technician/staff member.
- `POST /api/v1/tickets/{id}/status` - Update ticket lifecycle status (in progress, resolved with note, closed).
- `POST /api/v1/tickets/{id}/comments` - Add internal or customer-facing staff comment.

## Inventory & Material Management (`/api/v1/inventory`, `/api/v1/suppliers`, `/api/v1/serials`)
- `GET /api/v1/suppliers` - List material suppliers.
- `POST /api/v1/suppliers` - Register a new material supplier (Admin, Manager).
- `GET /api/v1/suppliers/{id}` - Get supplier details.
- `PATCH /api/v1/suppliers/{id}` - Update supplier contact/tax details.
- `DELETE /api/v1/suppliers/{id}` - Soft-delete a supplier (Admin).
- `GET /api/v1/inventory/items` - Search and list inventory items with category and low-stock filters.
- `GET /api/v1/inventory/low-stock` - List all items running below safety stock thresholds.
- `POST /api/v1/inventory/items` - Create material catalog item with category, unit, and serialized flag.
- `GET /api/v1/inventory/items/{id}` - View material item details and current stock.
- `PATCH /api/v1/inventory/items/{id}` - Update material specifications, units, or active status.
- `POST /api/v1/inventory/stock-in` - Receive stock from supplier, validating and recording serialized barcodes.
- `POST /api/v1/inventory/stock-out` - Issue materials/serials to customer project with non-negative check and warranty start.
- `POST /api/v1/inventory/adjust` - Adjust warehouse stock count with mandatory audit reason.
- `GET /api/v1/inventory/movements` - View complete audit ledger of all stock movements.
- `GET /api/v1/customers/{customer_id}/materials` - View list of all materials and installed serial numbers for a customer.
- `GET /api/v1/serials/{serial_no}` - Reverse lookup panel/inverter serial number for customer and active warranty status.
- `PATCH /api/v1/serials/{id}/status` - Mark serial item defective or returned.

## In-App Notifications (`/api/v1/notifications`)
- `GET /api/v1/notifications` - List all in-app notifications for the current user (paginated).
- `GET /api/v1/notifications/unread-count` - Get unread notification badge count.
- `POST /api/v1/notifications/{id}/read` - Mark a single notification as read.
- `POST /api/v1/notifications/read-all` - Mark all unread notifications as read.

## Reports & Analytics (`/api/v1/reports`)
- `GET /api/v1/reports/dashboard` - Operations cockpit KPIs: leads, customers by stage, monthly sales, pending payments, active works, open KEDL demands, open tickets, low stock items (Admin, Manager).
- `GET /api/v1/reports/sales` - Salesperson performance breakdown: lead counts, conversions, and total revenue (Admin, Manager).
- `GET /api/v1/reports/payments` - Payment collection summary vs outstanding balance and mode distribution (Admin, Manager).
- `GET /api/v1/reports/work` - Work completion metrics grouped by installation team (Admin, Manager).
- `GET /api/v1/reports/kedl` - KEDL discom file statuses and open demand financial totals (Admin, Manager, KEDL).
- `GET /api/v1/reports/export/customers` - Download Excel (.xlsx) of all customer installation records.
- `GET /api/v1/reports/export/payments` - Download Excel (.xlsx) of complete payment transactions ledger.
- `GET /api/v1/reports/export/inventory` - Download Excel (.xlsx) of current warehouse stock and low-stock alerts.
