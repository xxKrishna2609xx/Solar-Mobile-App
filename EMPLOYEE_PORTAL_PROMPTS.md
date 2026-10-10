# 👷 SolarPro: Employee Portal Prompt Pack v3 (matched to the real codebase)

> **Based on:** your `PROJECT_ARCHITECTURE.md` (Backend complete, Flutter app already has role-based routing, `packages/solar_shared`, and feature folders).
> **This pack builds:** the **Employee Portal** inside the **existing** SolarPro Flutter app. It reuses what already exists and does not rebuild it.
> **Not included:** the **Login page UI** (`lib/features/auth`). Do not design, rebuild or restyle it.
> **Replaces:** the earlier `EMPLOYEE_PORTAL_PROMPTS.md` (which assumed a `SolarPro/app` folder and `lib/portals/`, neither of which matches your repo).

---

## 🔎 What I learned from your architecture file

| Your codebase | What it means for the prompts |
|---|---|
| `SolarPro/` **is** the Flutter app (`SolarPro/lib`, `SolarPro/pubspec.yaml`) | No `SolarPro/app`. All commands run from `SolarPro/`. |
| `packages/solar_shared/` already holds enums and models | It stays the **single source of shared contracts**. Do not create a second shared layer for models. |
| `lib/core/` (Dio client with JWT refresh, GoRouter with role redirects, Material 3 theme) | Extend these. Never create a second API client, router or theme. |
| `lib/features/` already has `auth, client, customers, dashboard, inventory, kedl, leads, notifications, payments, tickets, work_assignment` | Reuse their data layers (repositories, providers). Add employee-only screens in a new `lib/features/employee/` module. |
| `lib/shared/widgets/` has `sp_bottom_nav`, `sp_section_header`, `sp_stat_card` | Reuse these; add new common widgets with the same `sp_` prefix. |
| Theme: Sun Gold `#F59E0B`, Slate Dark `#0F172A` | The only colors to use. |
| Stack: Riverpod, GoRouter, Dio, **Retrofit** | Match the existing style (Retrofit clients where the app already uses them). |
| Money is **integer paise** everywhere (ADR-005/008) | The app must send and show paise correctly. Never use doubles for money. |
| 10-stage lifecycle with automatic transitions on the backend | The app calls endpoints only. It never sets a stage itself. |
| Payment flow `pending → sales_approved → verified (admin)`, row-locked, overpayment guard | Salesman can approve, only Admin verifies. |
| KEDL files: `name_change`, `load`, `net` | In the UI show **"Load Increase"** for the `load` file. |
| Service tickets only for `SYSTEM_LIVE` or `HANDED_OVER`; structure 2-10 photos, wiring 1-10, inverter 0-10 | Employee service screens respect these. |
| Backend endpoints documented in `Backend/docs/API.md` and `FLUTTER_INTEGRATION.md` | The agent must read these first. They are the contract. |

### ⚠️ Gaps between your notes and the documented backend (the agent will verify)
These are **not mentioned** in the architecture file, so they may not exist in the backend yet:
1. Roles: **Main Admin vs Co-Admin**, and separate **Electrician / Structure / Civil / Service** employee roles (the API map shows only Admin, Manager, Sales Rep, Technician, KEDL Staff).
2. Lead outcomes **Follow-up / Closed / Return**.
3. **Subsidy vs Non-subsidy** with **DCR / NDCR** panel type, plus full equipment details (inverter, structure, AC/DC/earthing wire, SPD ACDB/DCDB, solar meter, civil work and earthing notes).
4. **Loan details** with any number of installments.
5. **Free-form payment plan per customer** (no fixed percentages).
6. KEDL file label **Load Increase** (backend value is `load`; label only).

Prompt 1 checks each of these against `Backend/app/models`, `schemas` and `docs/API.md`, and writes what is missing to `SolarPro/docs/BACKEND_GAPS.md`. After that I can write a backend prompt (Step 11) to add them.

---

## 📁 Real Folder Layout (target)

```text
Solar Android App/                    ← workspace root
├── Backend/                          ← READ-ONLY for this pack
├── website/                          ← never touch
└── SolarPro/                         ← ALL Flutter work happens here
    ├── pubspec.yaml                  ← the ONE app pubspec
    ├── packages/solar_shared/        ← shared enums, models, contracts (extend, don't duplicate)
    ├── lib/
    │   ├── main.dart
    │   ├── core/                     ← constants, network (Dio), router, theme  (extend)
    │   ├── shared/widgets/           ← sp_* widgets  (extend)
    │   └── features/
    │       ├── auth/                 ← LOGIN. DO NOT TOUCH UI
    │       ├── client/               ← Client portal (existing)
    │       ├── dashboard/            ← Admin / vendor dashboard (existing)
    │       ├── leads/ customers/ payments/ kedl/ work_assignment/
    │       │   tickets/ inventory/ notifications/      ← existing, reuse their data layers
    │       └── employee/             ← NEW: Employee portal (this pack)
    │           ├── salesman/
    │           ├── site_work/        ← electrician, structure, civil
    │           ├── kedl/
    │           ├── service/
    │           └── common/
    ├── docs/                         ← create if missing
    └── tools/                        ← create if missing
```

**Boundary rules**
- `features/employee/**` may import `core/`, `shared/`, `solar_shared`, and the **data layer** (models, repositories, providers) of existing features.
- It must **not** import screens or widgets from `features/client` or `features/dashboard`, and must not edit them.
- If something is needed by two portals, move it to `shared/` or `solar_shared` (and tell me).

---

## 📌 How to Use This File

1. Paste **PROMPT 0 (Rules)** once and keep it as workspace rules.
2. Run the prompts **one at a time, in order**, in **Planning mode**. Read the plan before the agent builds.
3. After **every prompt**, run the **🔁 Compatibility Check** at the end. Do not continue until it passes.
4. Commit to git after every prompt.

### 📋 Prompt Index

| # | Prompt | Result |
|---|--------|--------|
| 0 | Rules and context | Project rules (paste once) |
| 1 | Repo audit, backend contract check, compatibility script | Reports only, no features |
| 2 | Employee shell and role routing | Extends existing router and dashboard |
| 3 | Salesman: Leads | Follow-up / Closed / Return |
| 4 | Salesman: Convert to customer | Subsidy, DCR/NDCR, full equipment form |
| 5 | Salesman: Payment plan, payments, loan | Payment plan set in the app, approvals, loan |
| 6 | Site teams: Electrician / Structure / Civil | Jobs, start, complete with photos |
| 7 | KEDL employee | Name Change, Load Increase, Net, demands |
| 8 | Service employee | Service tickets |
| 9 | Common features | Extend notifications, uploads, offline |
| 10 | Final integration test | Cross-portal end-to-end check |

---

## 🧠 PROMPT 0: Rules and Context (paste once)

```text
You are adding the EMPLOYEE PORTAL to SolarPro, an EXISTING Flutter app for a solar rooftop installation
and selling business in India. The app has one login page; after login the user's role decides the portal:
Admin (features/dashboard), Client (features/client) or Employee (features/employee, to be built). A
complete FastAPI backend already exists in the Backend folder. Everything must keep working together.

REPO FACTS (verify them, do not assume)
- Workspace root contains Backend/, SolarPro/ and website/.
- SolarPro/ is the Flutter app: lib/core (constants, network/api_client.dart with Dio + JWT refresh,
  router/app_router.dart with role-based redirects, theme/app_theme.dart), lib/features/* (feature-first),
  lib/shared/widgets/sp_*.dart, and packages/solar_shared (shared enums, models, contracts).
- State: flutter_riverpod. Routing: go_router. HTTP: dio + retrofit. UI: Material 3, Sun Gold #F59E0B,
  Slate Dark #0F172A.
- The backend contract is in Backend/docs/API.md, Backend/docs/FLUTTER_INTEGRATION.md and the OpenAPI spec.

RULES
0. WORKING LOCATION: Write code ONLY inside the SolarPro folder. Run flutter/dart commands from SolarPro.
   Backend/ and website/ are READ-ONLY: read them for reference, never modify them. If the backend needs a
   change, write it in SolarPro/docs/BACKEND_GAPS.md instead. In these prompts docs/ and tools/ mean
   SolarPro/docs and SolarPro/tools (create them if missing).
1. EXTEND, DON'T REBUILD. Before creating anything, search the repo for an existing equivalent (API client,
   router, theme, models, repositories, providers, widgets). Reuse or extend it. Never create a second
   API client, router, theme, token storage or shared-model layer.
2. The LOGIN PAGE UI (lib/features/auth) must not be created, redesigned or restyled. Only consume the
   session result and route by role.
3. New employee code goes in lib/features/employee/<area>/. Do not edit existing Admin (features/dashboard)
   or Client (features/client) screens. If an unavoidable change is needed there, list it in
   docs/PORTAL_COMPATIBILITY.md under "Needs approval" and wait for my OK.
4. The backend is the source of truth. Read API.md and FLUTTER_INTEGRATION.md first. If an endpoint or
   field you need does not exist, DO NOT invent it. Add it to docs/BACKEND_GAPS.md (endpoint, fields,
   reason) and build against a repository interface with a clearly marked mock implementation.
5. MONEY: all amounts are integer paise (Rs 1,000.00 = 100000). Use one shared helper in solar_shared to
   convert rupees input to paise and to format paise as INR with Indian grouping (1,25,000). Never use
   double for money.
6. SHARED CONTRACTS: enums and models used by more than one portal live in packages/solar_shared. Never
   duplicate them in a feature. After changing solar_shared, run code generation and make sure Admin and
   Client still compile and their tests pass.
7. STAGES are changed only by the backend as a side effect of actions. The app never sets a stage itself.
   Refresh the customer after each action.
8. Every list screen needs: loading, empty and error (with retry) states, pull to refresh, and pagination.
   Every form needs validation, a disabled submit while loading, and clear error messages.
9. Images: compress before upload (about 1600 px long side, quality about 75, backend limit 10 MB), show
   progress, allow retry. Site workers often have a weak network.
10. Respect role permissions in the UI AND handle 403 gracefully. Never rely on hiding a button as the only
    protection.
11. Write widget tests for key screens and unit tests for controllers and repositories. Keep
    `flutter analyze` clean. Do not break existing tests.
12. Work in small steps. Show a short plan first. At the end summarize: what was built, how to run it,
    what is still missing.

ROLES (owner's definition)
- Admin group: Main Admin (1), Co-Admin (4). Co-Admin has the same powers as Main Admin but cannot remove
  the Main Admin. They use the existing Admin portal.
- Employee group: Salesman, KEDL, Electrician, Structure, Civil, Service. They use the NEW Employee portal.
- Client: the customer, existing Client portal.
Map these to the backend's real role enum (Backend/app/models/enums.py). If the backend names differ
(for example Electrician/Structure/Civil being "labour" users with a team type), write the mapping in
docs/DECISIONS_FLUTTER.md and use it consistently.

CUSTOMER STAGES (already in the backend, in this order)
SALE_CONFIRMED, DOCUMENTS_RECEIVED, ADVANCE_VERIFIED, STRUCTURE_WORK, ELECTRICAL_WORK, CIVIL_WORK,
INSTALLATION_COMPLETE, KEDL_PROCESS, SYSTEM_LIVE, HANDED_OVER
```

---

## 🔍 PROMPT 1: Repo Audit, Backend Contract Check, Compatibility Script

```text
Follow the rules in PROMPT 0. This prompt writes REPORTS and one script. It builds NO feature screens.

GOAL: Understand the real code first, so the Employee portal fits it exactly and does not break Admin or
Client.

TASKS
1. FLUTTER INVENTORY: read SolarPro/pubspec.yaml, packages/solar_shared, lib/core, lib/shared and every
   folder in lib/features. Write docs/FLUTTER_INVENTORY.md listing:
   - For each feature: screens, providers, repositories, Retrofit clients and models it has
   - What is reusable by the Employee portal (with file paths)
   - How role-based routing and redirects work today (app_router.dart) and which roles are handled
   - Which Retrofit/Dio/Riverpod patterns and naming conventions the code uses (so new code matches)
2. DEPENDENCY AUDIT: for SolarPro/pubspec.yaml and packages/solar_shared/pubspec.yaml report SDK
   constraints, every dependency and version, duplicates doing the same job, declared-but-unused and
   used-but-undeclared packages, and `dart pub outdated` findings. Propose changes only when needed for
   the Employee portal; list them for my approval.
3. BACKEND CONTRACT CHECK: read Backend/docs/API.md, FLUTTER_INTEGRATION.md, Backend/app/models/enums.py,
   models and schemas. Compare with solar_shared enums and models and report every mismatch in field
   names, types, nullability and enum values. Pay special attention to these items from the owner's
   notes, and mark each as EXISTS, PARTIAL or MISSING in docs/BACKEND_GAPS.md:
   a) Roles: main_admin vs co_admin; salesman, kedl, electrician, structure, civil, service
   b) Lead outcomes follow_up / closed / returned
   c) Subsidy vs non-subsidy with DCR / NDCR panel type
   d) Equipment details: panel brand, watt, quantity; inverter brand, quantity, capacity, phase;
      structure brand, quantity, height; AC wire, DC wire, earthing wire (brand x size); SPD ACDB and
      DCDB (brand, details); solar meter (quantity, brand); civil work and earthing free text
   e) Loan: yes/no, bank name, amount, any number of installments
   f) Free-form payment plan per customer (no fixed percentages)
   g) KEDL file `load` (UI label "Load Increase"), plus name_change and net
   h) Employee-scoped list endpoints (a salesman sees only own leads/customers; a team sees only its
      work; KEDL and Service see only their assignments)
4. ROLE MAPPING: write docs/DECISIONS_FLUTTER.md with the mapping between the owner's roles and the
   backend roles, and the proposed landing route per role.
5. COMPATIBILITY SCRIPT: create tools/check_compat.dart (plus tools/check_compat.ps1 for Windows and
   tools/check_compat.sh) implementing the "Compatibility Check" at the end of this file. One command
   must run it and write docs/PORTAL_COMPATIBILITY.md. Record a baseline of the current state of Admin
   and Client (analyze and test results) so later steps can prove nothing regressed.

DO NOT: add feature screens, edit existing features, touch the login UI, or modify Backend.

DELIVERABLES: docs/FLUTTER_INVENTORY.md, docs/BACKEND_GAPS.md, docs/DECISIONS_FLUTTER.md,
docs/PORTAL_COMPATIBILITY.md (baseline), tools/check_compat.*.
ACCEPTANCE: reports exist and are accurate; the script runs on Windows; baseline shows the current
analyze/test status of the whole app.
```

---

## 🧭 PROMPT 2: Employee Shell and Role Routing

```text
Follow the rules in PROMPT 0. Prompt 1 must be complete (read docs/FLUTTER_INVENTORY.md and
docs/DECISIONS_FLUTTER.md first).

GOAL: After the EXISTING login succeeds, employees land in a new Employee portal. Admin and Client
routing must behave exactly as before.

TASKS
1. EXTEND the existing GoRouter (lib/core/router/app_router.dart) with an /employee route tree. Do not
   replace the router and do not change the redirects for Admin or Client roles, only add the Employee
   roles to the role-to-home mapping from docs/DECISIONS_FLUTTER.md.
2. ROUTE PROTECTION: Employee routes are only for employee roles. Employee users can never open Admin or
   Client routes (including deep links and notification taps), and vice versa. Unknown roles see a clear
   "Account not supported, contact admin" screen with logout.
3. EMPLOYEE SHELL in lib/features/employee/common, using the existing sp_bottom_nav and theme. Tabs by role
   (English labels):
   - Salesman: Home, Leads, Customers, Payments, Profile
   - Electrician / Structure / Civil: Home, My Jobs, Calendar, Profile
   - KEDL: Home, Files, Demands, Profile
   - Service: Home, Tickets, Profile
   Notifications bell in the app bar for all roles (reuse features/notifications and its unread count).
   Placeholder screens use an empty-state widget; real screens come in later prompts.
4. LOGOUT / ACCOUNT SWITCH: make sure logout clears tokens and invalidates every provider and cache, so
   a different user logging in on the same device never sees the previous user's data. Use the existing
   logout flow; extend it only if needed.
5. TESTS: a routing test matrix over every role (Main Admin, Co-Admin, Salesman, KEDL, Electrician,
   Structure, Civil, Service, Client): each lands on the right portal and is blocked from the others.

ACCEPTANCE
- Existing Admin and Client behaviour is unchanged (baseline tests still pass).
- Each employee role sees only its own tabs.
- Routing matrix passes. Compatibility Check passes.
```

---
## 🧑‍💼 PROMPT 3: Salesman, Leads

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.
LOCATION: lib/features/employee/salesman/leads/. Reuse the data layer of lib/features/leads (repository,
providers, models). Do not edit its existing screens.

GOAL: Salesman lead management.

BUSINESS FLOW
- Leads reach a salesman in two ways: (a) the Admin assigns a lead to him, (b) he adds a lead himself and
  it is assigned to him with a Reference note.
- The salesman decides every lead's outcome: FOLLOW-UP, CLOSED or RETURN.

TASKS
1. Leads tab with filter chips: All, New, Follow-up, Closed, Returned. Search by name or phone. Show a
   source tag ("Assigned by Admin" or "Added by me"). A salesman sees only his own leads (use the backend's
   scoping; also verify it in a test).
2. Add Lead form: name, mobile (10-digit Indian validation), address/area, expected capacity in kW
   (optional), reference (free text), notes. Auto-assign to the current salesman.
3. Lead detail: all fields, status history timeline, quick actions Call, WhatsApp, open in maps.
4. Status actions: Follow-up (needs next follow-up date and note), Return (needs reason), Closed (opens the
   Convert flow in Prompt 4).
5. "Today's follow-ups" card on the Home tab and local reminders for follow-up dates.
6. Endpoints: GET/POST /leads (check API.md for the exact status and update calls). If the backend lacks
   follow_up / closed / returned (for example it uses "lost"), map the labels in the UI, add the gap to
   docs/BACKEND_GAPS.md and keep the mapping in ONE place.

ACCEPTANCE
- Add, edit, change status and filter work. Another salesman's leads never appear.
- Compatibility Check passes.
```

---

## 🧾 PROMPT 4: Salesman, Convert Lead to Customer

```text
Follow the rules in PROMPT 0. Prompts 1 to 3 must be complete.
LOCATION: lib/features/employee/salesman/customers/. Reuse lib/features/customers and lib/features/leads
data layers.

GOAL: When a lead is Closed, the salesman converts it into a customer by filling the full sale details.
Use a multi-step form (stepper) with local draft saving so nothing is lost if the app closes. The
conversion endpoint is POST /leads/{id}/convert (atomic: creates the customer and the client login).

STEP 1 Customer: name, mobile, address, "Use current location" button (GPS latitude and longitude with
permission handling and a map preview), final work price (rupees input, sent as paise).

STEP 2 Subsidy type and panels:
- Choose SUBSIDY or NON-SUBSIDY. Subsidy means DCR panels, Non-subsidy means NDCR panels.
- Panel brand, panel capacity (Watt), panel quantity (same fields for both).
- Show total system capacity in kW = capacity(W) x quantity / 1000.

STEP 3 Inverter and structure:
- Inverter: brand, quantity, capacity, phase (1-phase or 3-phase).
- Structure: brand, quantity, height.

STEP 4 Wiring and protection:
- AC wiring, DC wiring, earthing wire: each brand x size.
- SPD: ACDB (brand + details) and DCDB (brand + details).
- Solar meter: quantity + brand.

STEP 5 Extra work: Civil work (free text) and Earthing (free text), both blank by default.

STEP 6 Documents (POST /customers/{id}/documents): E-Bill, Aadhaar, PAN, Cancelled Cheque, Registry
(property paper). Camera or gallery, compressed, per-file progress and retry, and a checklist of missing
documents. The backend may move the stage to DOCUMENTS_RECEIVED automatically.

STEP 7 Review and submit: summary, then convert. Show success with the customer ID and go to the
customer's Payments tab (Prompt 5).

RULES
- Brand fields: searchable dropdown with "Add new brand" to keep names consistent; store as text if the
  backend has no brand master.
- Fields the backend does not support yet (see docs/BACKEND_GAPS.md): keep them in the form, save them in
  the local draft, send only what the API accepts, and mark them clearly in code with a TODO(backend-gap)
  comment. Do not drop the fields.
- Validate each step before Next. Autosave a local draft per lead and resume it.

ACCEPTANCE
- A closed lead converts with all supported fields and documents.
- Switching Subsidy/Non-subsidy changes the panel type label (DCR/NDCR).
- Draft survives an app restart. Compatibility Check passes.
```

---

## 💰 PROMPT 5: Salesman, Payment Plan, Payments and Loan

```text
Follow the rules in PROMPT 0. Prompts 1 to 4 must be complete.
LOCATION: lib/features/employee/salesman/payments/. Reuse lib/features/payments data layer.

GOAL: Manage how each customer pays, inside the app.

BUSINESS RULE
There are NO fixed or predefined payment terms. Never hard-code percentages or stages. The salesman
defines the payment plan for every customer.

TASKS
1. PAYMENT PLAN BUILDER (per customer): any number of milestones, each with a free-text title, either a
   percentage OR a fixed amount (toggle), and an optional due-condition note. Show a live running total;
   percent milestones must total 100% (or amounts must equal the final price). If not, warn and ask for
   confirmation before saving. Reorder, edit and delete are allowed until the plan's first payment is
   approved, after which the plan is locked for the salesman. If the backend has no payment-plan
   endpoint, record it in docs/BACKEND_GAPS.md and keep the plan in a mock repository.
2. PAYMENTS LIST for a customer: summary card (final price, verified total, pending, balance) and each
   payment with milestone, amount, mode, reference number, date, proof photo and status
   (pending, sales_approved, verified, rejected). All amounts are paise in the model.
3. RECORD PAYMENT: POST /customers/{id}/payments with proof photo.
4. CLIENT SUBMISSIONS queue "Payments to approve": payments the customer submitted with a photo. Actions:
   Approve (POST /payments/{id}/approve) or Reject with a required reason. After approval show a chip
   "Waiting for Admin". The salesman can NEVER verify; verification is Admin only.
5. LOAN DETAILS (per customer): Loan yes/no. If yes: bank name, loan amount, and a list of installments of
   ANY length (amount, expected date, received/pending). Installment total must not exceed the loan
   amount. If the backend has no loan fields, record the gap and use the mock repository.

ACCEPTANCE
- Different customers can have different plans (3 milestones for one, 5 for another).
- Totals and balance are correct in paise. The overpayment error from the backend is shown clearly.
- Compatibility Check passes (payment statuses match Admin and Client exactly).
```

---

## 🏗️ PROMPT 6: Site Teams (Electrician, Structure, Civil)

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.
LOCATION: lib/features/employee/site_work/. Reuse lib/features/work_assignment data layer.

GOAL: One site-work module for Electrician, Structure and Civil employees. The employee's role decides
the work type. They see only their own team's jobs. A task can only belong to a team of the same
discipline (backend rule).

TASKS
1. MY JOBS with tabs Today, Upcoming, Completed. Card: customer name, area, work type, dates, status chip.
2. JOB DETAIL
   - Limited customer info only: name, mobile, address, map directions. NEVER show prices, payments or
     documents to site employees.
   - Scope of work by role (from the customer's equipment details when available):
     Structure: brand, quantity, height. Electrical: inverter, AC/DC/earthing wire, SPD (ACDB, DCDB),
     solar meter. Civil: civil work notes and earthing notes.
   - Actions: Start (POST /work-assignments/{id}/status), Add photos (POST /work-assignments/{id}/photos,
     up to 10 per upload), Complete. Completing requires at least 1 uploaded photo (backend rule); the app
     blocks it earlier and confirms before completing.
3. CALENDAR from GET /work-assignments/calendar for the team.
4. OFFLINE TOLERANCE: queue photo uploads and status changes locally, sync when online, show a
   "pending sync" indicator.
5. The backend moves stages (STRUCTURE_WORK, ELECTRICAL_WORK, CIVIL_WORK, INSTALLATION_COMPLETE). The app
   only calls endpoints.

ACCEPTANCE
- An Electrician never sees Structure or Civil jobs; nobody sees another team's jobs.
- Completing without a photo is blocked.
- Offline start/complete syncs later. Compatibility Check passes.
```

---

## 🗂️ PROMPT 7: KEDL Employee

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.
LOCATION: lib/features/employee/kedl/. Reuse lib/features/kedl data layer.

GOAL: The KEDL (Discom work) employee tracks the three discom files per customer.

FILE TYPES: NAME CHANGE (name_change), LOAD INCREASE (backend value `load`, show the label "Load
Increase"), NET FILE (net).

TASKS
1. FILES tab grouped by customer; filter by file type, status and "has open demand". Only files assigned
   to this employee.
2. FILE DETAIL: status flow Not started -> Submitted -> Demand raised -> Demand paid -> Approved (or
   Rejected) via POST /kedl-files/{id}/status; application number, submitted and approved dates, remarks;
   documents upload and view; status history timeline.
3. DEMANDS tab: all open demands sorted by due date, overdue highlighted. Add a demand
   (POST /kedl-files/{id}/demands: description, amount in paise, due date) and mark paid or waived
   (PATCH /kedl-demands/{id}) with an optional receipt.
4. HOME dashboard: counts by file type and status, open demands, overdue demands.
5. Backend rules: raising a demand sets demand_raised automatically; paying all demands sets demand_paid;
   approving the Net file moves the customer to SYSTEM_LIVE. Refresh the customer after each action.

ACCEPTANCE
- Three file types with full demand handling. Overdue demands clearly flagged.
- Compatibility Check passes (KEDL enums match everywhere).
```

---

## 🛠️ PROMPT 8: Service Employee

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.
LOCATION: lib/features/employee/service/. Reuse lib/features/tickets data layer.

GOAL: The Service employee handles tickets created in the Client portal.

TICKET TYPES: Structure issue (2-10 photos), Wiring issue (1-10 photos), Inverter fault (0-10 photos,
optional error code). Tickets exist only for SYSTEM_LIVE or HANDED_OVER customers.

TASKS
1. TICKETS tab: Assigned to me, In progress, Resolved. Filter by type and priority (GET /tickets with
   filters). Show ticket number, customer, type, date, status.
2. TICKET DETAIL: customer info with directions; description and image gallery (full screen, zoom); the
   customer's system details and warranty info; comment thread; actions Start work, Add visit photos,
   Resolve (note required), via POST /tickets/{id}/status.
3. SERIAL LOOKUP: enter or scan a serial number (GET /serials/{serial_no}) to show customer and warranty
   status.
4. Notifications when a ticket is assigned or the customer replies.
5. Service employees see only tickets assigned to them.

ACCEPTANCE
- Resolve needs a note; the customer sees the update in the Client portal.
- Compatibility Check passes (ticket enums and statuses match the Client portal).
```

---

## 🔔 PROMPT 9: Common Features (extend, don't duplicate)

```text
Follow the rules in PROMPT 0. Prompts 1 to 8 must be complete.
LOCATION: extend lib/features/notifications, lib/core and lib/shared. Employee-only screens go in
lib/features/employee/common. If a service already exists, extend it instead of creating another.

TASKS
1. NOTIFICATIONS: reuse the existing in-app notification feature (GET /notifications, unread-count,
   read, read-all). Make sure FCM registration (POST /auth/fcm-token) and foreground, background and
   terminated handling work for employee roles. Notification taps deep-link to the right lead, job, KEDL
   file, payment or ticket for the user's role, and never to another portal.
2. PROFILE: name, role, phone, team, logout.
3. OFFLINE and UPLOADS: one shared upload service (compression, progress, retry, cancel) and one offline
   queue with a "pending sync" screen, used by all employee features. If the Client or Admin portals
   already have an upload helper, reuse it rather than writing a second one.
4. ERROR HANDLING: friendly messages mapped from the backend error format
   {"error": {"code","message","details"}}.
5. PERMISSIONS: one helper for camera, gallery, location and notifications with explanation dialogs.
6. Release notes: document the Android release build steps in docs/RELEASE.md.

ACCEPTANCE
- Tapping a notification opens the correct screen for the user's role.
- Interrupted uploads survive an app restart. Compatibility Check passes.
```

---

## ✅ PROMPT 10: Final Integration Test

```text
Follow the rules in PROMPT 0. All previous prompts must be complete.

GOAL: Prove Admin, Employee and Client work together in the one app and against the real backend.

TASKS
1. Run the full Compatibility Check. Fix every conflict inside lib/features/employee, lib/core,
   lib/shared and solar_shared. For conflicts in Admin or Client code, list them with proposed changes and
   wait for my approval.
2. ROUTING MATRIX: re-run the all-roles routing test. Also test expired token, refresh failure, a role
   change on the server, a deep link into another portal, and logout then login as a different role on
   the same device (no previous data may remain).
3. END-TO-END journey against the running backend (docker compose up), as an automated test or a manual QA
   checklist, naming the portal used at each step:
   - Admin assigns a lead to a Salesman (Admin)
   - Salesman marks it Closed and converts it with equipment details and documents; defines a payment plan
     (Employee)
   - Client logs in, sees status, submits a payment with a photo (Client)
   - Salesman approves, Admin verifies, customer reaches ADVANCE_VERIFIED (Employee + Admin)
   - Admin schedules Structure, Electrical and Civil work; each team completes with photos (Admin + Employee)
   - Admin initialises KEDL files; the KEDL employee processes Name Change, Load Increase and Net file with
     a demand (Admin + Employee)
   - Net file approved, customer SYSTEM_LIVE, client sees it
   - Client raises a Structure ticket with 2+ photos; the Service employee resolves it (Client + Employee)
4. Write docs/EMPLOYEE_PORTAL.md: features per role, screens, folder structure, how to run and build,
   known gaps (link BACKEND_GAPS.md).
5. `flutter build apk --release` succeeds.

ACCEPTANCE
- The journey completes with no manual database edits.
- docs/PORTAL_COMPATIBILITY.md shows zero unresolved conflicts, or each remaining one has an owner and fix.
```

---

## 🔁 COMPATIBILITY CHECK (run after every prompt)

> Paste this into Antigravity after each prompt, or run `tools/check_compat.ps1` (Windows) once Prompt 1 has created it.

```text
Run the COMPATIBILITY CHECK for SolarPro. Admin = lib/features/dashboard (and the admin-facing features),
Client = lib/features/client, Employee = lib/features/employee, Shared = lib/core, lib/shared and
packages/solar_shared. Compare results with the baseline recorded in Prompt 1.

A. PACKAGES AND DEPENDENCIES
   1. Run `flutter pub get` in SolarPro and in packages/solar_shared. Report failures.
   2. List each dependency and which areas (Admin, Client, Employee, Shared) import it. Flag packages
      declared but unused, used but undeclared, and two libraries doing the same job.
   3. Flag any package added for the Employee portal that changes a version used by Admin or Client.
   4. Run `dart pub outdated` and list security or deprecation problems.
   5. Run code generation (build_runner for retrofit/freezed/json_serializable) and confirm there is no
      leftover diff in generated files.

B. BOUNDARIES AND SHARED CONTRACT
   6. features/employee must not import screens or widgets from features/client or features/dashboard.
      List violations. Confirm there are no circular imports.
   7. No feature defines its own copy of an enum, model, API client, token key, theme value or common
      widget that already exists in solar_shared, core or shared. List duplicates.
   8. Compare solar_shared enums and models with Backend/docs/API.md, FLUTTER_INTEGRATION.md and the
      OpenAPI spec: field names, types, nullability, enum values (roles, stages, lead, payment, work,
      KEDL and ticket statuses). Confirm all money fields are integer paise.
   9. Confirm one API base URL, one auth interceptor, one refresh flow and one error format are used
      everywhere.

C. NO REGRESSION IN ADMIN AND CLIENT
   10. `git diff` shows no change in lib/features/dashboard, lib/features/client or lib/features/auth,
       unless listed under "Needs approval". Confirm the login UI files are unchanged.
   11. Admin and Client tests and analyzer results are the same as or better than the baseline.

D. ROUTING
   12. Run the all-roles routing matrix (Main Admin, Co-Admin, Salesman, KEDL, Electrician, Structure,
       Civil, Service, Client). Each lands on the right portal and is blocked from the others. Confirm
       logout clears every provider and cache.

E. HYGIENE
   13. Run `flutter analyze` and `flutter test`. Report failures.
   14. Search for hard-coded values that must come from the backend or enums (role names, stage names,
       payment percentages). Hard-coded payment terms must not exist anywhere.
   15. Confirm nothing was modified in Backend/ or website/, and no Flutter file exists outside SolarPro/.

OUTPUT
- Update docs/PORTAL_COMPATIBILITY.md with PASS or FAIL for sections A to E, the conflicts found, and the
  exact fix proposed for each.
- Fix issues inside Employee, Shared and core immediately (never the login UI).
- For issues in Admin, Client or Backend, DO NOT change them. Add them to "Needs approval" and ask me.
- End with one line: "ALL PORTALS COMPATIBLE" or "CONFLICTS FOUND: <count>".
```

---

## 🧯 Troubleshooting Prompts

**The agent builds things that already exist**
```text
Stop. Re-read PROMPT 0 rule 1. Search the repo for the existing API client, router, theme, models,
repositories and widgets, and reuse them. Delete the duplicate you created and run the Compatibility Check.
```

**The agent edits Admin or Client screens**
```text
Stop. Re-read PROMPT 0 rule 3. Revert your changes to lib/features/dashboard and lib/features/client with
git, put the new code in lib/features/employee, and list anything unavoidable under "Needs approval".
```

**The agent invents endpoints or fields**
```text
Stop. Re-read PROMPT 0 rule 4. Check Backend/docs/API.md and FLUTTER_INTEGRATION.md. Move every endpoint or
field that does not exist into docs/BACKEND_GAPS.md and use a mock repository for it.
```

**The agent touches the login page, Backend or website**
```text
Stop. The login UI (lib/features/auth), Backend/ and website/ must not be changed. Revert those changes
with git and keep only the post-login role routing.
```

**Money looks wrong**
```text
Re-read PROMPT 0 rule 5. All amounts are integer paise. Use the shared money helper to convert rupees to
paise and to format INR with Indian grouping. Remove every double-based money calculation.
```