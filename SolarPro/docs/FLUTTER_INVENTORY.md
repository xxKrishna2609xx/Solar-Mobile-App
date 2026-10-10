# SolarPro — Flutter Codebase Inventory & Reusability Audit

> **Generated:** Prompt 1 (Repository Audit)  
> **Scope:** `SolarPro/lib/`, `packages/solar_shared/`, `SolarPro/pubspec.yaml`  
> **Target:** Foundation for the Employee Portal (`lib/features/employee/`)

---

## 1. Feature-by-Feature Inventory

The existing Flutter codebase in `SolarPro/lib/features/` is structured around feature-first directories. However, several modules currently declare internal mock/view models (`_Lead`, `_Customer`, etc.) directly inside presentation screen files rather than having dedicated repository or entity layers.

| Feature Directory | Existing Screens & Widgets | Existing Models / Entities | Reusability for Employee Portal |
| :--- | :--- | :--- | :--- |
| **`lib/features/auth`** | `login_screen.dart`<br>`otp_screen.dart`<br>`onboarding_screen.dart`<br>`splash_screen.dart` | Handled via `SharedPreferences` + `ApiClient` session tokens (`kAccessToken`, `kUserRole`, etc.) | **Read-Only / Consume Only**.<br>The existing login flow stores the user role. Employee portal will be routed based on this role without modifying login UI. |
| **`lib/features/dashboard`** | `vendor_dashboard_screen.dart`<br>`desktop_overview_pane.dart`<br>`widgets/desktop_header.dart`<br>`widgets/desktop_sidebar.dart` | `_RA` (recent activity), `_PipeRow` | **Admin Portal Only**.<br>Contains Super Admin / Vendor KPI overviews. Employee portal will have its own role-scoped shell (`features/employee/common/`). |
| **`lib/features/leads`** | `presentation/screens/leads_screen.dart` | `_Lead` (internal class in screen) | **Partially Reusable**.<br>`ApiClient.getLeads()` and `createLead()` are in `api_client.dart`. Salesman portal will reuse the lead API calls, but UI will live in `features/employee/salesman/leads/`. |
| **`lib/features/customers`** | `presentation/screens/customers_screen.dart`<br>`presentation/screens/customer_detail_screen.dart` | `_Customer`, `_CustomerInfo`, `_DocItem`, `_PaymentRecord`, `_StageInfo` | **High Reusability**.<br>Customer details, stage chips, and document list views provide templates for Salesman conversion & project detail tracking. |
| **`lib/features/payments`** | `presentation/screens/payments_screen.dart` | `_Payment` (internal class in screen) | **High Reusability**.<br>Payment status pills (`pending`, `sales_approved`, `verified`, `rejected`) and amount formatting will be used in Salesman payment approvals. |
| **`lib/features/work_assignment`**| `presentation/screens/work_assignment_screen.dart` | `_WorkJob` (internal class in screen) | **High Reusability**.<br>Structure, Electrical, and Civil site teams will reuse work assignment data definitions, job status transitions, and photo upload triggers. |
| **`lib/features/kedl`** | `presentation/screens/kedl_screen.dart` | `_KedlFile` (internal class in screen) | **High Reusability**.<br>File cards for `name_change`, `load` (Load Increase), and `net`, plus demand status badges will be reused by the KEDL officer portal. |
| **`lib/features/tickets`** | `presentation/screens/tickets_screen.dart` | `_Ticket` (internal class in screen) | **High Reusability**.<br>Issue categories (`structure`, `wiring`, `inverter`) and status workflows directly inform the Service Employee portal. |
| **`lib/features/inventory`** | `presentation/screens/inventory_screen.dart` | `_InventoryItem`, `_MoveItem`, `_SerialItem` | **Reference / Read-Only**.<br>Useful for technicians/salesmen looking up serialized inverters or solar panels. |
| **`lib/features/notifications`**| `presentation/screens/notifications_screen.dart` | `_Notif` (internal class in screen) | **High Reusability**.<br>In-app notification list and unread count badges are shared across all employee roles. |
| **`lib/features/client`** | `presentation/screens/client_dashboard_screen.dart` | Client home data structures | **Protected / Client Portal Only**.<br>Never imported into `features/employee/`. |
| **`lib/features/admin`** | `presentation/screens/admin_approvals_screen.dart` | Superadmin approval cards | **Protected / Admin Portal Only**. |

---

## 2. Core & Shared Layer Reusability

### 2.1. Networking (`lib/core/network/api_client.dart`)
- **Single Instance**: Singleton `ApiClient()` wraps a centralized `Dio` instance.
- **Interceptors**:
  - `onRequest`: Automatically injects `Authorization: Bearer <token>` from `SharedPreferences` (`AppConstants.kAccessToken`).
  - Logs requests and responses via `dart:developer`.
- **Backend URL Resolution**:
  - `AppConstants.useHostedBackend` toggles between Render cloud (`https://solar-mobile-app.onrender.com/api/v1`) and local dev (`http://localhost:8000/api/v1` or Android emulator `http://10.0.2.2:8000/api/v1`).
- **Reuse Directive for Employee Portal**:
  - All employee repositories will consume `ApiClient().dio` or helper methods (`get`, `post`, `patch`, `delete`).
  - Never instantiate a second `Dio` or HTTP client.

### 2.2. Shared Widgets (`lib/shared/widgets/`)
- `sp_bottom_nav.dart` (`SpBottomNav`): Reusable bottom navigation with customizable `_NavItem` list and active index.
- `sp_section_header.dart` (`SpSectionHeader`): Section title with optional action button ("View All", "+ Add").
- `sp_stat_card.dart` (`SpStatCard`): Metric card supporting icon, label, value, trend, and accent tint.
- **Naming Rule**: All new common widgets created for the employee portal must use the `sp_` prefix and be placed in `lib/shared/widgets/` if shared across portals.

### 2.3. Theme & Styling (`lib/core/theme/app_theme.dart`)
- **Brand Colors**:
  - Primary Accent: **Sun Gold (`#F59E0B` / `#F5A623`)**
  - Dark Surface / Background: **Slate Dark (`#0F172A` / `#0A1628`)**
  - Card Fill: Deep Navy (`#1E293B` / `#162238`)
  - Border: Subtle Slate (`#334155`)
  - Text Primary: Pure White (`#FFFFFF`), Secondary: Muted Gray (`#94A3B8`)
- **Typography**: Google Fonts (Poppins / Inter) with Material 3 typography conventions.

---

## 3. Current Routing & Role Redirect Architecture

- **Router**: Configured in `lib/core/router/app_router.dart` using `GoRouter`.
- **Current Role Handling**:
  - Initial location is `/login`.
  - Roles currently stored in `SharedPreferences` on login: `client`, `vendor` (admin), `sales`.
  - Routes currently defined:
    - Auth: `/`, `/onboarding`, `/login`, `/otp`
    - Vendor / Admin: `/vendor/dashboard`, `/vendor/leads`, `/vendor/customers`, `/vendor/payments`, `/vendor/work-assignments`, `/vendor/kedl`, `/vendor/inventory`, `/admin/approvals`
    - Client: `/client/dashboard`, `/client/tickets`
    - Shared: `/notifications`
- **Gap Identified**:
  - There is currently **no `/employee` route tree** and no programmatic `redirect` guard in `app_router.dart` to intercept deep links or enforce role isolation.
  - In Prompt 2, `app_router.dart` will be extended with role-based redirection and the `/employee` route hierarchy without modifying existing Admin or Client paths.

---

## 4. Coding Conventions to Match

1. **State Management**: `flutter_riverpod` (v2.6.x) using `StateNotifierProvider` or `FutureProvider` / `NotifierProvider`.
2. **Models**: Immutable Dart classes with `fromJson` / `toJson` serialization. All financial values must be stored as `int` paise.
3. **Async / Error Handling**: Dio exceptions mapped to user-friendly messages using the standard backend envelope `{"error": {"code": "...", "message": "...", "details": ...}}`.
4. **List Screens**: Must provide loading shimmer, empty placeholder, error banner with retry button, and pull-to-refresh (`RefreshIndicator`).
