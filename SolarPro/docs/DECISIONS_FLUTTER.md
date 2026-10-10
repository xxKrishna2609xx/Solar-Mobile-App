# SolarPro — Flutter Architecture Decisions & Role Mappings

> **Generated:** Prompt 1 (Role Mapping & Flutter ADRs)  
> **Applies to:** `SolarPro/lib/` and future `SolarPro/packages/solar_shared/`

---

## ADR-F01: Role Mapping (Owner Definition ↔ Backend Role)

### Context
The owner defines 8 distinct user roles:
- **Admin Group**: Main Admin (1), Co-Admin (4)
- **Employee Group**: Salesman, KEDL, Electrician, Structure, Civil, Service
- **Client**: Solar rooftop consumer / system owner

The existing backend implementation (`Backend/app/models/enums.py`) defines `UserRole`:
`admin`, `manager`, `sales`, `labour`, `technician`, `kedl`, `office_staff`, `client`.
Teams (`TeamType` / `WorkType`) define `structure`, `electrical`, `civil`.

### Decision Matrix

| Owner Business Role | Backend `UserRole` | Context / Team Attribute | Portal Assigned | Default Landing Route |
| :--- | :--- | :--- | :--- | :--- |
| **Main Admin** | `admin` | System superadmin | Admin Portal | `/vendor/dashboard` |
| **Co-Admin** | `manager` / `admin` | Secondary administrator | Admin Portal | `/vendor/dashboard` |
| **Salesman** | `sales` | Sales executive | Employee Portal | `/employee/salesman/home` |
| **Electrician** | `technician` / `labour` | Team `type == electrical` | Employee Portal | `/employee/site/home` |
| **Structure Tech**| `technician` / `labour` | Team `type == structure` | Employee Portal | `/employee/site/home` |
| **Civil Tech** | `technician` / `labour` | Team `type == civil` | Employee Portal | `/employee/site/home` |
| **KEDL Employee** | `kedl` | Discom paperwork officer | Employee Portal | `/employee/kedl/home` |
| **Service Tech** | `technician` | Post-installation service | Employee Portal | `/employee/service/home` |
| **Client** | `client` | Homeowner customer | Client Portal | `/client/dashboard` |

---

## ADR-F02: Portal Isolation & Route Hierarchies

### Decision
Three distinct route hierarchies are defined:
1. **Admin Portal (`/vendor/**`, `/admin/**`)**:
   - Strictly reserved for `admin` and `manager` roles.
   - Houses overall business dashboard, all leads/customers, company payments ledger, and user management.
2. **Client Portal (`/client/**`)**:
   - Strictly reserved for `client` role.
   - Houses the single customer home dashboard, 10-stage timeline, payments submission, and service tickets.
3. **Employee Portal (`/employee/**`)**:
   - Dedicated shell for employee roles with role-specific bottom navigation tabs.
   - Sub-routes:
     - `/employee/salesman/*` (Home, Leads, Customers, Payments, Profile)
     - `/employee/site/*` (Home, My Jobs, Calendar, Profile)
     - `/employee/kedl/*` (Home, Files, Demands, Profile)
     - `/employee/service/*` (Home, Tickets, Profile)

Cross-portal navigation is guarded by GoRouter `redirect` logic. Any attempt by an unauthorized role to access another portal redirects to their respective home screen.

---

## ADR-F03: Money Invariant (Integer Paise)

### Decision
In accordance with Backend ADR-005 and ADR-008:
- All monetary values in models, forms, and network requests must be represented as **integer paise** (`int`).
- Floating-point calculations (`double`) for currency are prohibited.
- Formatting helper standard:
  ```dart
  class PaiseCurrencyFormatter {
    static String formatINR(int paise) {
      final rupees = paise ~/ 100;
      // Formats as Indian Numbering (e.g. 1,25,000)
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: (paise % 100 == 0) ? 0 : 2,
      ).format(paise / 100.0);
    }

    static int rupeesToPaise(num rupees) {
      return (rupees * 100).round();
    }
  }
  ```

---

## ADR-F04: Boundary Rules for `lib/features/employee`

### Decision
1. Code inside `lib/features/employee/` may import:
   - `lib/core/**` (constants, network client, theme)
   - `lib/shared/**` (shared `sp_*` UI widgets)
   - `packages/solar_shared/**` (contracts and enums)
   - The data layers (repositories, providers, models) of `features/leads`, `features/customers`, `features/payments`, etc.
2. Code inside `lib/features/employee/` must **never** import UI screens or private widgets from `lib/features/client/` or `lib/features/dashboard/`.
3. The login page (`lib/features/auth`) must never be modified.
