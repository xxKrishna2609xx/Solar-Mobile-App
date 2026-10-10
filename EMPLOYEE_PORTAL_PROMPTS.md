# 👷 Employee Portal: Antigravity Prompt Pack (Flutter, Android)

> **App:** Solar Installation & Sales Management, **Employee Portal**
> **Platform:** Android (Flutter). Keep the code iOS-ready, but test on Android only.
> **Not included:** the **Login page UI** (already designed by the owner). Do not design, rebuild or restyle it.

---

## 📌 How to Use This File

1. Fill in the **Workspace Paths** below.
2. Paste **PROMPT 0 (Rules)** once and keep it as workspace rules.
3. Run the prompts **one at a time, in order**, in **Planning mode**. Read the plan before the agent builds.
4. After **every prompt**, run the **🔁 Compatibility Check** (Section at the end). Do not start the next prompt until it passes.
5. Commit to git after every prompt.

### 🗂️ Workspace Paths (fill these in)

```text
FLUTTER_ROOT         = ./SolarPro                          # ONLY folder where Flutter code may be written
EMPLOYEE_PORTAL_PATH = ./SolarPro/employee_portal          # this app (to build)
ADMIN_PORTAL_PATH    = ./SolarPro/admin_portal             # existing or planned
CLIENT_PORTAL_PATH   = ./SolarPro/client_portal            # existing or planned
SHARED_PACKAGE_PATH  = ./SolarPro/packages/solar_shared    # create if missing (see Prompt 1)
BACKEND_ROOT         = ./Backend                           # FastAPI backend, separate folder (READ-ONLY here)
BACKEND_OPENAPI      = ./Backend/docs/openapi.json         # or the running /openapi.json URL (READ-ONLY)
```

> 📁 **The `SolarPro` folder is dedicated to all Flutter files.** Every Flutter/Dart file, package, script, test and doc for the portals must live inside it. The backend lives in its own separate folder named **`Backend`** and is never edited from these prompts. If your Admin or Client portal already sits at a different path inside `SolarPro`, change the paths above to match before you start.
>
> If the Admin or Client portal does not exist yet, tell the agent. It should still build the shared package so those portals can use it later.

### 📋 Prompt Index

| # | Prompt | Result |
|---|--------|--------|
| 0 | Rules and context | Project rules (paste once) |
| 1 | Audit and shared foundation | Dependency audit, shared package, compatibility script |
| 2 | App shell and role routing | Navigation and role-based home (no login UI) |
| 3 | Salesman: Leads | Lead list, add lead, Follow-up / Closed / Return |
| 4 | Salesman: Convert to customer | Full customer form (subsidy, DCR/NDCR, equipment) |
| 5 | Salesman: Payments and loan | Payment plan set inside the app, payment records, loan details |
| 6 | Site teams: Electrician / Structure / Civil | Assigned jobs, start, complete with photos |
| 7 | KEDL employee | Name Change, Load Increase, Net file, demands |
| 8 | Service employee | Service tickets |
| 9 | Common features | Notifications, profile, offline, uploads |
| 10 | Final integration test | End-to-end check with Admin and Client portals |

---

## 🧠 PROMPT 0: Rules and Context (paste once)

```text
You are building the EMPLOYEE PORTAL of a mobile app for a solar rooftop installation and
selling business in India. The app is built with Flutter (Android first). The same product also has an
ADMIN portal and a CLIENT portal, and a Python FastAPI backend. All of them must work together without
conflicts.

RULES
0. WORKING LOCATION: Work ONLY inside the `SolarPro` folder (FLUTTER_ROOT = ./SolarPro). It is dedicated
   to all the Flutter files. Create, edit, run and test every Flutter/Dart file, package, tool script,
   test and doc under SolarPro. Never create Flutter files outside it, and never place files in the
   workspace root. Run all flutter/dart commands from inside SolarPro (or its sub-folders). The backend
   lives in a separate folder named `Backend` (BACKEND_ROOT = ./Backend). The Backend folder and
   BACKEND_OPENAPI are outside SolarPro: you may READ them for reference, but never modify
   anything outside SolarPro. If something in Backend (or anywhere outside SolarPro) must change, write it in
   SolarPro/docs/BACKEND_GAPS.md instead. Any path written as docs/... or tools/... in these prompts
   means SolarPro/docs/... and SolarPro/tools/...
1. The LOGIN PAGE UI already exists (designed by the owner). Never create, redesign or restyle it. Only
   consume its result: after a successful login, read the authenticated user and route by role.
2. The Employee Portal contains ONLY employee features. Admin features (user management, verifying
   payments as employer, reports, inventory admin) belong to the Admin portal. Do not build them here.
3. The backend is the source of truth. Use the OpenAPI spec at BACKEND_OPENAPI. If an endpoint or field
   you need does not exist, DO NOT invent it silently. Add it to docs/BACKEND_GAPS.md (endpoint, fields,
   reason) and build against a clearly marked repository interface with a mock implementation.
4. Models, enums, API client, auth/token handling and design tokens must be SHARED across portals through
   the shared package (SHARED_PACKAGE_PATH). Never duplicate them inside the Employee Portal.
5. Architecture: feature-first folders, clean layering (presentation / domain / data), Riverpod for state,
   go_router for navigation, dio for HTTP, freezed + json_serializable for models,
   flutter_secure_storage for tokens, intl for dates and currency (INR).
6. Money is shown in INR with the Indian digit grouping (e.g. 1,25,000). Never use floating point math for
   money; use integers (paise) or a decimal type consistently with the backend contract.
7. Every list screen needs: loading state, empty state, error state with retry, pull to refresh, and
   pagination. Every form needs validation, a disabled submit while loading, and clear error messages.
8. Images: compress before upload (max about 1600 px on the long side, quality about 75), show upload
   progress, and allow retry. Site workers often have a weak network.
9. Respect role permissions in the UI AND handle 403 responses gracefully. Never rely on hiding a button
   as the only protection.
10. Write widget tests for key screens and unit tests for controllers and repositories. Keep
    `flutter analyze` clean.
11. Work in small steps. Show a short plan first. After building, summarize: what was built, how to run
    it, and what is still missing.

ROLES
- Admin group: Main Admin (1), Co-Admin (4). A Co-Admin has the same powers as the Main Admin but cannot
  remove the Main Admin. (Admin portal only. The roles still exist in the shared enums.)
- Employee group: Salesman, KEDL, Electrician, Structure, Civil, Service. (THIS APP)
- Client: the customer. (Client portal)

CUSTOMER STAGES (shared enum, in this order)
SALE_CONFIRMED, DOCUMENTS_RECEIVED, ADVANCE_VERIFIED, STRUCTURE_WORK, ELECTRICAL_WORK, CIVIL_WORK,
INSTALLATION_COMPLETE, KEDL_PROCESS, SYSTEM_LIVE, HANDED_OVER
```

---

## 🔍 PROMPT 1: Audit and Shared Foundation

```text
Follow the rules in PROMPT 0.

GOAL: Before writing any Employee Portal feature, make sure the three portals can share code and
dependencies without conflicts.

TASKS
0. LOCATION CHECK: confirm the `SolarPro` folder exists in the workspace (create it if missing) and that
   everything you create will be inside it. Create SolarPro/docs and SolarPro/tools if needed.
1. Locate the Admin portal (ADMIN_PORTAL_PATH) and the Client portal (CLIENT_PORTAL_PATH) inside
   SolarPro. If one does not exist, note it in the report and continue.
2. DEPENDENCY AUDIT: read every pubspec.yaml (Admin, Client, Employee, shared package). Produce
   docs/PORTAL_COMPATIBILITY.md with:
   - Flutter SDK and Dart SDK constraints for each portal
   - A table of every dependency, its version in each portal, and whether versions CONFLICT
   - The state management, routing, HTTP, serialization and storage libraries each portal uses
   - Libraries used in only one portal that should be shared
   - Recommendation for a single aligned version set (prefer the versions the existing portals already use;
     do not upgrade anything in the Admin or Client portal without listing it for my approval)
3. SHARED PACKAGE: create or extend SHARED_PACKAGE_PATH (a Dart/Flutter package named solar_shared) holding:
   - Enums: UserRole, CustomerStage, LeadStatus, PaymentStatus, WorkType, WorkStatus, KedlFileType,
     KedlFileStatus, TicketType, TicketStatus, SubsidyType, PanelType, Phase
   - Models: User, Team, Lead, Customer (with equipment details), PaymentPlan, Payment, Loan,
     WorkAssignment, KedlFile, KedlDemand, ServiceTicket, AppNotification
   - ApiClient (dio, base URL from env, auth interceptor, refresh-token rotation, standard error mapping
     for the backend error format {"error": {"code","message","details"}})
   - TokenStorage (single storage key names reused by all portals)
   - Design tokens: colors, text styles, spacing, radius. Reuse the existing Admin/Client/login design
     tokens if present. Do not invent a new look.
   - Common widgets: AppButton, AppTextField, StatusChip, EmptyState, ErrorState, ImageUploadGrid
   Generate models from the OpenAPI spec when possible; otherwise write them by hand and verify against
   the spec.
4. CONTRACT CHECK: compare the shared models and enums against BACKEND_OPENAPI. List mismatches in
   docs/BACKEND_GAPS.md. Known points to verify:
   - Roles: the backend may only have admin, sales, labour (with team type), kedl, client. This product
     needs main_admin, co_admin, salesman, kedl, electrician, structure, civil, service, client.
   - Lead outcome statuses must be: follow_up, closed, returned (the word is "Return", not "Lost").
   - KEDL file types must be: name_change, load_increase, net.
   - Customer must support: subsidy type, DCR/NDCR panel type, full equipment details, loan details,
     and a free-form payment plan.
5. COMPATIBILITY SCRIPT: create tools/check_portals.sh (and tools/check_portals.ps1 for Windows) that
   implements the "Compatibility Check" described at the end of this file, and writes its result to
   docs/PORTAL_COMPATIBILITY.md. Make it runnable with one command.
6. Wire the Employee Portal's pubspec.yaml to depend on solar_shared (path dependency). Do not add
   libraries that duplicate what the shared package provides.

DO NOT: create any login screen UI; change Admin/Client code without listing it first.

DELIVERABLES: docs/PORTAL_COMPATIBILITY.md, docs/BACKEND_GAPS.md, the solar_shared package,
tools/check_portals.sh.
ACCEPTANCE: `flutter pub get` succeeds in all existing portals; the script runs and reports zero version
conflicts (or lists each conflict with a proposed fix).
```

---

## 🧭 PROMPT 2: App Shell and Role Routing

```text
Follow the rules in PROMPT 0. Prompt 1 must be complete.

GOAL: Create the Employee Portal shell. The login page already exists and must not be touched.

TASKS
1. App bootstrap: ProviderScope, theme from solar_shared tokens, go_router with a redirect guard:
   - Not authenticated: go to the existing login route (use the existing route name or path).
   - Authenticated: route by role. Reject non-employee roles with a clear screen telling the user to use
     the correct portal (Admin or Client).
2. After login, read the user via GET /auth/me and keep it in an auth state provider (role, name, phone,
   team).
3. Role-based home with bottom navigation (labels in English):
   - Salesman: Home, Leads, Customers, Payments, Profile
   - Electrician / Structure / Civil: Home, My Jobs, Calendar, Profile
   - KEDL: Home, Files, Demands, Profile
   - Service: Home, Tickets, Profile
   Notifications bell in the app bar for every role.
4. Create placeholder screens for each tab with the shared EmptyState widget (real screens are built in
   later prompts).
5. Global handlers: 401 triggers token refresh, then logout if refresh fails; 403 shows a permission
   message; no-internet banner.
6. Logout action in Profile that clears tokens through the shared TokenStorage.

ACCEPTANCE
- Each of the 6 employee roles lands on the correct home and sees only its own tabs.
- A client or admin account is blocked with the correct message.
- Compatibility Check passes.
```

---

## 🧑‍💼 PROMPT 3: Salesman, Leads

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.

GOAL: Salesman lead management.

BUSINESS FLOW
- Lead sources: (a) the Admin assigns a lead to the Salesman, (b) the Salesman adds a lead himself and it is
  assigned to him with a Reference note (who referred the customer).
- The Salesman decides the outcome of every lead: FOLLOW-UP, CLOSED, or RETURN.

TASKS
1. Leads tab with filter chips: All, New, Follow-up, Closed, Returned. Search by name or phone. Show the
   lead source tag ("Assigned by Admin" or "Added by me"). Salesman sees only his own leads.
2. Add Lead form: name, mobile (10-digit Indian validation), address/area, expected capacity (kW,
   optional), reference (free text), notes. The lead is assigned to the current salesman automatically.
3. Lead detail screen: all fields, status history timeline, quick actions: Call, WhatsApp, open map.
4. Status actions:
   - Follow-up: requires next follow-up date and a note
   - Return: requires a reason
   - Closed: leads to the Convert flow (Prompt 4)
5. Follow-up reminders: a "Today's follow-ups" card on Home, and schedule local notifications for follow-up
   dates.
6. Use the backend endpoints for leads. Where the backend uses "lost", map it to "Return" in the UI and add
   the difference to docs/BACKEND_GAPS.md.

ACCEPTANCE
- Add, edit, change status and filter work against the API (or the mock if listed in BACKEND_GAPS.md).
- Another salesman's leads never appear.
- Compatibility Check passes.
```

---

## 🧾 PROMPT 4: Salesman, Convert Lead to Customer

```text
Follow the rules in PROMPT 0. Prompts 1 to 3 must be complete.

GOAL: When a lead is Closed, the Salesman converts it into a customer by filling the full sale details.
Use a multi-step form (stepper) with draft saving so nothing is lost if the app closes.

STEP 1: Customer
- Customer name, mobile, address, and a "Use current location" button (GPS latitude and longitude, with
  permission handling and a map preview), final work price.

STEP 2: Subsidy type and panels
- Choose SUBSIDY or NON-SUBSIDY.
  - Subsidy  -> panel type DCR
  - Non-subsidy -> panel type NDCR
- Panel details (same fields for both): panel brand, panel capacity (Watt), panel quantity.
- Auto-calculate and show total system capacity in kW = capacity(W) x quantity / 1000.

STEP 3: Inverter and structure
- Inverter: brand, quantity, capacity, phase (1-phase or 3-phase).
- Structure: brand, quantity, height.

STEP 4: Wiring and protection
- AC wiring: brand x size
- DC wiring: brand x size
- Earthing wire: brand x size
- SPD: ACDB (brand + details), DCDB (brand + details)
- Solar meter: quantity + brand

STEP 5: Extra work
- Civil work: free-text field (blank by default)
- Earthing: free-text field (blank by default)

STEP 6: Documents
- Upload: E-Bill, Aadhaar, PAN, Cancelled Cheque, Registry (property paper). Camera or gallery, compressed,
  with per-file progress and retry. Show a checklist of which documents are still missing.

STEP 7: Review and submit
- Summary screen. On submit call the convert-lead endpoint. The backend creates the customer and the
  client login (mobile number). Show success with the customer ID.
- Payment plan and loan are handled in Prompt 5. After submit, navigate to the customer's Payments tab.

RULES
- Brand fields: use a searchable dropdown with "Add new brand" so the same brand names get reused. Store as
  free text if the backend has no brand master (note in BACKEND_GAPS.md).
- "Brand x size" fields use two inputs (brand and size) plus a unit hint (e.g. sq.mm).
- Validate all required fields per step before allowing Next.
- Autosave a local draft per lead and resume it.

ACCEPTANCE
- A closed lead can be converted with every field above and documents attached.
- Switching Subsidy and Non-subsidy changes the panel type label (DCR or NDCR) correctly.
- Draft survives an app restart.
- Compatibility Check passes (customer model matches the shared package and backend).
```

---

## 💰 PROMPT 5: Salesman, Payment Plan, Payments and Loan

```text
Follow the rules in PROMPT 0. Prompts 1 to 4 must be complete.

GOAL: Manage how each customer pays, entirely inside the app.

IMPORTANT BUSINESS RULE
There are NO fixed or predefined payment terms. Never hard-code percentages or stages. The Salesman
defines the payment plan for every customer inside the app.

TASKS
1. PAYMENT PLAN BUILDER (per customer)
   - Add any number of milestones. Each milestone has: title (free text, e.g. "Advance for Structure"),
     either a percentage OR a fixed amount (toggle), and an optional due condition note
     (e.g. "7 days after generation").
   - Show a live running total. Percent milestones must total 100% (or amounts must total the final price).
     If they do not match, show a clear warning and ask for confirmation before saving.
   - Reorder, edit and delete milestones until the first payment of the plan is approved. After that, the
     plan is locked for the Salesman (changes need the Admin portal).
2. PAYMENTS LIST for a customer
   - Summary card: final price, total paid (verified), pending approval, balance.
   - Each payment: milestone, amount, mode (cash, UPI, bank transfer, cheque), reference number, date,
     proof photo, status (pending, approved by sales, verified by admin, rejected).
3. RECORD PAYMENT: the Salesman records a payment against a milestone with a proof photo.
4. CLIENT SUBMISSIONS: a queue "Payments to approve" where the Salesman sees payments the customer
   submitted with a photo. Actions: Approve or Reject (rejection needs a reason). Final verification
   by the employer happens in the Admin portal, so show a status chip "Waiting for Admin".
5. LOAN DETAILS (per customer)
   - Loan status: Yes or No.
   - If Yes: bank name, loan amount, and a list of installments with ANY number of rows
     (1st installment, 2nd installment, and so on). Each installment has amount, expected date and status
     (pending or received).
   - Validate that the installment total does not exceed the loan amount.
6. Reuse the shared Payment and PaymentPlan models. Money is INR with Indian grouping.

ACCEPTANCE
- Different customers can have completely different plans (e.g. 3 milestones for one, 5 for another).
- Totals and balance are always correct.
- Salesman can approve or reject client submissions; they cannot mark anything as admin-verified.
- Compatibility Check passes (payment statuses match the Admin and Client portals exactly).
```

---

## 🏗️ PROMPT 6: Site Teams (Electrician, Structure, Civil)

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.

GOAL: One site-work module used by Electrician, Structure and Civil employees. The employee's role decides
which work type they see. They see only jobs assigned to their team.

TASKS
1. MY JOBS list with tabs: Today, Upcoming, Completed. Each card shows customer name, area, work type,
   scheduled dates and a status chip (pending, in progress, completed).
2. JOB DETAIL
   - Limited customer info only: name, mobile, address, map link/directions. Do NOT show prices, payments or
     documents to site employees.
   - Scope of work for that role, pulled from the customer's equipment details:
     - Structure: structure brand, quantity, height
     - Electrical: inverter, AC/DC/earthing wire (brand x size), SPD (ACDB, DCDB), solar meter
     - Civil: civil work notes and earthing notes (free text)
   - Actions: Start work, Add photos (up to 10 per upload), Complete work.
   - Complete requires at least 1 photo and an optional remark. Confirm before completing.
3. CALENDAR view of the team's schedule by date.
4. Offline tolerance: queue photo uploads and status changes locally and sync when online, with a visible
   "pending sync" indicator.
5. Starting and completing jobs updates the customer stage on the backend. The app must only call the
   endpoints; it never sets the stage itself.

ACCEPTANCE
- An Electrician cannot see Structure or Civil jobs, and no one sees jobs of another team.
- Completing a job without a photo is blocked.
- Offline start and complete actions sync correctly later.
- Compatibility Check passes (work statuses and stage enums match the Admin and Client portals).
```

---

## 🗂️ PROMPT 7: KEDL Employee

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.

GOAL: The KEDL (Discom work) employee tracks the discom files for each customer.

FILE TYPES (exactly three): NAME CHANGE, LOAD INCREASE, NET FILE.

TASKS
1. FILES tab: list grouped by customer, filter by file type, status and "has open demand". Show only files
   assigned to this employee.
2. FILE DETAIL
   - Status flow: Not started -> Submitted -> Demand raised -> Demand paid -> Approved (or Rejected)
   - Fields: application number, submitted date, approved date, remarks
   - Documents: upload and view (photos or PDF)
   - Status history timeline
3. DEMANDS tab: all open demands across files, sorted by due date, overdue ones highlighted.
   - Add demand: description, amount (optional), due date
   - Mark paid or waived, with an optional receipt upload
4. HOME dashboard: counts per file type and status, open demands, overdue demands.
5. Only call the backend status endpoints. The customer stage changes (KEDL_PROCESS, SYSTEM_LIVE when the
   Net file is approved) are done by the backend. The app should refresh the customer after each change.

ACCEPTANCE
- Three file types per customer with full demand handling.
- Overdue demands are clearly flagged.
- Compatibility Check passes (KEDL enums match everywhere).
```

---

## 🛠️ PROMPT 8: Service Employee

```text
Follow the rules in PROMPT 0. Prompts 1 and 2 must be complete.

GOAL: The Service employee handles customer service tickets created in the Client portal.

TICKET TYPES: Structure issue (2 to 10 images), Wiring issue (photos), Inverter fault.

TASKS
1. TICKETS tab: tabs Assigned to me, In progress, Resolved. Filter by type and priority. Show ticket number,
   customer, type, created date and status.
2. TICKET DETAIL
   - Customer info (name, mobile, address with directions)
   - Description and image gallery (full screen, zoom)
   - System details of the customer (inverter, panels) and warranty info when available
   - Comment thread with the customer and staff
   - Actions: Start work, Add visit photos, Resolve (resolution note is required), Request more info
3. Look up equipment by serial number (text entry or a scanner using the camera) to show the customer and
   warranty status, if the backend endpoint exists. Otherwise record it in BACKEND_GAPS.md.
4. Notifications when a ticket is assigned or the customer replies.

ACCEPTANCE
- Service employees see only tickets assigned to them.
- Resolving needs a note; the customer sees the update in the Client portal.
- Compatibility Check passes (ticket enums and statuses match the Client portal).
```

---

## 🔔 PROMPT 9: Common Features

```text
Follow the rules in PROMPT 0. Prompts 1 to 8 must be complete.

TASKS
1. NOTIFICATIONS: Firebase Cloud Messaging integration (register the device token with the backend, handle
   foreground, background and terminated states). In-app notification list with unread badge, mark as
   read, and deep link to the related lead, job, file, payment or ticket.
2. PROFILE: show name, role, phone, team; logout. (Editing the profile is not needed.)
3. OFFLINE: a shared offline queue for uploads and status changes with retry and a "pending sync" screen.
4. UPLOADS: one shared upload service (compression, progress, retry, cancel) used by all features.
5. ERROR HANDLING: friendly messages mapped from the backend error codes; a global "something went wrong"
   fallback; log errors with a crash reporting hook (Crashlytics if available).
6. PERMISSIONS: a single helper for camera, gallery, location and notification permissions with
   explanation dialogs.
7. APP HYGIENE: app icon and name placeholders, splash handled by the existing design, release build
   config (R8, signing placeholders) documented in docs/RELEASE.md.

ACCEPTANCE
- Tapping a notification opens the right screen for the user's role.
- Uploads survive app restarts when interrupted.
- Compatibility Check passes.
```

---

## ✅ PROMPT 10: Final Integration Test

```text
Follow the rules in PROMPT 0. All previous prompts must be complete.

GOAL: Prove the Employee, Admin and Client portals work together.

TASKS
1. Run the full Compatibility Check and fix every conflict that lives in the Employee Portal or the
   shared package. For conflicts in the Admin or Client portals, list them with proposed changes. Do not
   change those portals without my approval.
2. Write an integration test script (or a manual QA checklist if automation is not possible) for this
   end-to-end journey, with the portal used at each step:
   - Admin assigns a lead to a Salesman (Admin portal)
   - Salesman marks it Closed and converts it with equipment details, documents and a payment plan (Employee)
   - Client logs in and sees the status; submits a payment with a photo (Client)
   - Salesman approves; Admin verifies; customer reaches ADVANCE_VERIFIED (Employee + Admin)
   - Admin assigns Structure, Electrical and Civil teams; each team completes its job with photos (Admin + Employee)
   - Admin initialises KEDL files; the KEDL employee processes Name Change, Load Increase and Net file,
     including a demand (Admin + Employee)
   - Net file approved -> customer stage SYSTEM_LIVE (client sees it)
   - Client raises a Structure ticket with 2+ images; the Service employee resolves it (Client + Employee)
3. Verify that role switching works: logging out and logging in as different employee roles on the same
   device shows the right UI each time, and no data from the previous user remains.
4. Generate docs/EMPLOYEE_PORTAL.md: features per role, screens list, folder structure, how to run and
   build, known gaps (link BACKEND_GAPS.md).

ACCEPTANCE
- The full journey completes across portals with no manual database edits.
- docs/PORTAL_COMPATIBILITY.md shows zero unresolved conflicts, or each remaining one has an owner and a fix.
```

---

## 🔁 COMPATIBILITY CHECK (run after every prompt)

> Paste this into Antigravity after each prompt, or run `tools/check_portals.sh` once Prompt 1 has created it.

```text
Run the PORTAL COMPATIBILITY CHECK across EMPLOYEE_PORTAL_PATH, ADMIN_PORTAL_PATH, CLIENT_PORTAL_PATH and
SHARED_PACKAGE_PATH. For each portal that exists:

A. PACKAGES
   1. Run `flutter pub get` and `flutter pub deps`. Report failures.
   2. Compare every dependency version across the portals. Flag any package with different major or
      minor versions, and any that resolves to different versions in the lockfiles.
   3. Compare Flutter and Dart SDK constraints. Flag mismatches.
   4. Flag packages that do the same job in different portals (for example two state-management or two
      HTTP libraries) and any package that is declared but not imported anywhere.
   5. Run `dart pub outdated` and list packages with known security or deprecation issues.

B. SHARED CONTRACT
   6. Confirm no portal defines its own copy of an enum, model, API client, token storage key or design
      token that already exists in solar_shared. List duplicates.
   7. Compare enums and models in solar_shared against BACKEND_OPENAPI. List every difference in field
      names, types, nullability and enum values (stages, lead statuses, payment statuses, work statuses,
      KEDL types and statuses, ticket types and statuses, roles).
   8. Confirm all portals use the same API base URL variable, auth header, refresh-token flow and error
      format.

C. BEHAVIOUR
   9. Confirm every Flutter/Dart file created so far lives inside SolarPro. List any stray file outside it
      and move it into the correct SolarPro folder.
   9b. Run `flutter analyze` and `flutter test` in each portal and the shared package. Report failures.
   10. Search for hard-coded strings that must come from the backend or shared enums (role names, stage
       names, payment percentages). Flag any hard-coded payment terms (they must not exist).

OUTPUT
- Update docs/PORTAL_COMPATIBILITY.md with a PASS or FAIL for each section, a list of conflicts, and the
  exact fix proposed for each.
- Fix issues that are inside the Employee Portal or solar_shared immediately.
- For issues in the Admin or Client portals or the backend, DO NOT change them. Add them to a "Needs
  approval" list and stop to ask me.
- End with a one-line verdict: "ALL PORTALS COMPATIBLE" or "CONFLICTS FOUND: <count>".
```

---

## 🧯 Troubleshooting Prompts

**If the agent invents endpoints or fields**
```text
Stop. Re-read PROMPT 0 rule 3. List every endpoint and field you assumed that is not in BACKEND_OPENAPI,
move them to docs/BACKEND_GAPS.md, and replace them with a mock repository.
```

**If the agent creates files outside the SolarPro folder**
```text
Stop. Re-read PROMPT 0 rule 0. All Flutter files must live only inside the SolarPro folder. Move every
file you created outside it into the correct place under SolarPro, fix the import and path references,
and run the Compatibility Check again. Do not modify anything outside SolarPro.
```

**If the agent starts designing the login page**
```text
Stop. The login page UI already exists and must not be created or changed. Remove anything you added for
it and only keep the post-login role routing.
```

**If the agent duplicates models or enums**
```text
Move all models and enums into solar_shared and import them from there. Run the Compatibility Check.
```

**If a screen does not match the existing look**
```text
Use only the design tokens and common widgets from solar_shared (and the existing login screen styling).
Do not introduce new colors, fonts or component styles.
```
