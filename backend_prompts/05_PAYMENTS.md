# 💰 STEP 05: Payments

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Steps 02 to 04 must be complete.

## 🎯 Goal
Multi-stage payments per customer with photo proof and an approval flow.

## 🧾 Business Rules (from the owner's notes)
- A customer has a **final price** and **many payments** (1st payment, 2nd, ... any number).
- Payments are **verified by the employer (admin)**.
- A client can **submit a payment with a photo**, which needs **approval by the salesman**. **(CONFIRM: does the admin also verify after the salesman?)**
- Default design: `pending → approved_by_sales → verified (admin)`; also `rejected`.

## 📋 Tasks

### 1. Models + migration
**Payment**: `id, customer_id, stage_no (1,2,3...), amount, mode (cash|upi|bank_transfer|cheque|other), reference_no, paid_on (date), proof_key, status (pending|sales_approved|verified|rejected), submitted_by, submitted_by_role, sales_approved_by, sales_approved_at, verified_by, verified_at, rejection_reason, remarks, is_deleted`

**PaymentAuditLog**: `id, payment_id, action, actor_id, old_status, new_status, created_at`

### 2. Endpoints
- `POST /api/v1/customers/{id}/payments` (multipart: fields + proof image)
  - `client`: only for their own record, status becomes `pending`
  - `sales` (own customers) or `admin`: can record a payment directly; admin entries can be `verified` immediately
- `GET /api/v1/customers/{id}/payments` list + totals: `final_price, total_verified, total_pending, balance`
- `GET /api/v1/payments/pending` queues: the sales queue (own customers) and the admin queue (`sales_approved`)
- `POST /api/v1/payments/{id}/sales-approve` (sales who owns the customer, or admin)
- `POST /api/v1/payments/{id}/verify` (**admin only**)
- `POST /api/v1/payments/{id}/reject` with a required reason
- `PATCH` on a payment is allowed only while `pending`; verified payments are immutable (admin correction creates an audit entry).

### 3. Logic
- Validate that the sum of non-rejected payments cannot exceed `final_price` (return a clear error).
- When the **first** payment becomes `verified`, move the customer stage to `ADVANCE_VERIFIED` (if currently `DOCUMENTS_RECEIVED`) and write StageHistory.
- Every status change writes a PaymentAuditLog row. Use DB transactions and row locking to prevent double approval.
- Proof image: jpg/png/pdf, max 10 MB, stored via the storage abstraction, returned as a presigned URL.

### 4. Tests
- Full flow: client submits → sales approves → admin verifies → totals and stage update
- Overpayment rejected, double approval blocked
- Another salesperson cannot approve; a client cannot approve their own payment
- Verified payment cannot be edited

## 🚫 Do Not
- Do not integrate a payment gateway.
- Do not use floats for money.

## ✅ Acceptance Checklist
- [ ] Totals and balance are correct across many payments
- [ ] Approval flow and role limits enforced
- [ ] Audit log written for every change
- [ ] Stage auto-moves on first verified payment
- [ ] Tests pass, migration applies cleanly
