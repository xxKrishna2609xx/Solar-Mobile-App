# SolarPro — Dependency Audit & Package Health Report

> **Generated:** Prompt 1 (Dependency Audit)  
> **Scope:** `SolarPro/pubspec.yaml`, `packages/solar_shared/`  
> **Flutter Version:** Flutter 3.44.2 (Channel stable) • Dart 3.12.2

---

## 1. SDK Constraints & Environment

| Manifest | SDK Constraint | Flutter SDK |
| :--- | :--- | :--- |
| `SolarPro/pubspec.yaml` | `>=3.0.0 <4.0.0` | `sdk: flutter` |
| `packages/solar_shared/` | *Manifest missing* (requires creation) | N/A |

---

## 2. Dependencies Inventory (`SolarPro/pubspec.yaml`)

### 2.1. Production Dependencies

| Category | Package | Declared Version | Resolved Version | Usage in Project | Status / Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **State Management** | `flutter_riverpod` | `^2.5.1` | `2.6.1` | Global state container & DI | Active |
| | `riverpod_annotation` | `^2.3.5` | `2.6.1` | Riverpod code generation | Active |
| **Routing** | `go_router` | `^14.2.7` | `14.8.1` | Declarative app routing | Active (`app_router.dart`) |
| **Networking** | `dio` | `^5.4.3` | `5.4.3+1` | HTTP requests & interceptors | Active (`api_client.dart`) |
| | `retrofit` | `^4.1.0` | `4.4.1` | Type-safe REST client generator | Declared for future API clients |
| **Storage** | `shared_preferences` | `^2.2.3` | `2.5.5` | Token & session storage | Active (`api_client.dart`) |
| **UI & Animations** | `animate_do` | `^3.3.4` | `3.3.9` | Entry animations | Active |
| | `lottie` | `^3.1.2` | `3.1.2` | Animated JSON illustrations | Active (`AppAssets`) |
| | `shimmer` | `^3.0.0` | `3.0.0` | Skeleton loading effects | Active |
| | `flutter_animate` | `^4.5.0` | `4.5.0` | Fluent chaining animations | Active |
| **Typography & Icons** | `google_fonts` | `^6.2.1` | `6.3.3` | Brand fonts (Poppins, Inter) | Active (`app_theme.dart`) |
| | `iconsax` | `^0.0.8` | `0.0.8` | Modern outline/bold icons | Active |
| | `phosphor_flutter` | `^2.1.0` | `2.1.0` | Alternative icon family | *Duplicate icon pack* |
| | `cupertino_icons` | `^1.0.6` | `1.0.9` | iOS style icons | Standard Flutter icon pack |
| **Forms & Utilities** | `intl` | `^0.19.0` | `0.19.0` | Currency, dates & formatting | Active |
| | `uuid` | `^4.4.0` | `4.5.1` | UUIDv4 client generation | Active |
| | `equatable` | `^2.0.5` | `2.1.0` | Value equality for objects | Active |
| | `dartz` | `^0.10.1` | `0.10.1` | Functional programming (Either) | Declared |
| | `freezed_annotation` | `^2.4.4` | `2.4.4` | Immutable data modeling | Active |
| | `json_annotation` | `^4.9.0` | `4.9.0` | JSON serialization tags | Active |
| | `pin_code_fields` | `^8.0.1` | `8.0.1` | 6-digit OTP UI widget | Active (`otp_screen.dart`) |
| | `fl_chart` | `^0.68.0` | `0.68.0` | Charts & analytics | Active (`vendor_dashboard_screen.dart`) |
| | `timeline_tile` | `^2.0.0` | `2.0.0` | 10-stage project timeline | Active (`customer_detail_screen.dart`) |
| | `dotted_border` | `^2.1.0` | `2.1.0` | Dashed file upload boxes | Active |
| | `badges` | `^3.1.2` | `3.2.0` | Notification bell counter badge | Active |
| | `country_code_picker` | `^3.0.0` | `3.0.0` | International phone selector | Active (`login_screen.dart`) |

### 2.2. Dev Dependencies

| Package | Declared Version | Resolved Version | Role |
| :--- | :--- | :--- | :--- |
| `flutter_test` | `sdk: flutter` | `sdk: flutter` | Unit & widget test runner |
| `flutter_lints` | `^4.0.0` | `4.0.0` | Official Flutter lint rules |
| `build_runner` | `^2.4.11` | `2.4.13` | Code generation coordinator |
| `riverpod_generator` | `^2.4.0` | `2.4.0` | Generates Riverpod providers |
| `freezed` | `^2.5.2` | `2.5.2` | Generates copyWith & union types |
| `json_serializable` | `^6.8.0` | `6.8.0` | Generates fromJson/toJson methods |
| `retrofit_generator` | `^8.1.0` | `8.2.1` | Generates Dio REST API implementations |

### 2.3. Dependency Overrides
- `path_provider_foundation: 2.3.2` is currently overridden in `pubspec.yaml` to ensure macOS/iOS platform build compatibility.

---

## 3. Package Redundancies & Findings

1. **Dual Icon Libraries**:
   - Both `iconsax: ^0.0.8` and `phosphor_flutter: ^2.1.0` are declared. Currently, `iconsax` is the primary icon set used throughout `app_theme.dart` and `vendor_dashboard_screen.dart`.
   - *Recommendation:* Keep both for now to avoid breaking existing vendor dashboard screens, but standardize on `iconsax` for the new Employee portal screens.
2. **`packages/solar_shared/` Status**:
   - The directory exists at `SolarPro/packages/solar_shared/` with empty subdirectories (`enums`, `models`, `network`, `storage`, `theme`, `widgets`).
   - It currently lacks a `pubspec.yaml` and is not imported in `SolarPro/pubspec.yaml`.
   - *Recommendation for later prompts:* When shared models (e.g. `PaiseCurrency`, common enums) are formalized, add a clean `pubspec.yaml` to `packages/solar_shared/` and reference it as a path dependency in `SolarPro/pubspec.yaml`.

---

## 4. `dart pub outdated` Summary

- **Dependencies on latest constraint-compatible versions**: 16 direct packages have newer major releases (e.g., `go_router` 14 -> 18, `flutter_riverpod` 2.6 -> 3.4).
- **Stability Assessment**: Current pinned versions in `pubspec.lock` are fully functional and pass `flutter analyze` with 0 issues. Upgrading major versions is NOT recommended during employee portal implementation to prevent breaking changes in existing Riverpod providers and GoRouter setup.

---

## 5. Proposed Dependency Changes (Awaiting User Approval)

No new third-party dependencies are required for Prompt 1. All necessary libraries (Riverpod, GoRouter, Dio, SharedPreferences, Material 3, Iconsax, Intl) are already installed and resolving cleanly.
