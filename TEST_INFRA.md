# E2E Test Infra: Ăn Lành (LTD-)

## Test Philosophy
- Opaque-box, requirement-driven testing based strictly on `ORIGINAL_REQUEST.md` and user-facing specifications.
- Complete independence from device hardware / emulators using `sqflite_common_ffi` (in-memory SQLite), `package:http/testing.dart` (`MockClient`), and mockable `NotificationService` contract.
- Methodology: Category-Partition (Tier 1) + Boundary Value Analysis (Tier 2) + Pairwise Combinatorial Testing (Tier 3) + Real-World Workload Testing (Tier 4).

## Feature Inventory
| # | Feature | Source (requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|----------------------|:------:|:------:|:------:|
| 1 | User Authentication (Register, Login, Session, Validation) | ORIGINAL_REQUEST §R1 & §R4 | 5 | 5 | ✓ |
| 2 | Database Product Search (Local SQLite query, name/barcode filtering) | ORIGINAL_REQUEST §R1 & §R4 | 5 | 5 | ✓ |
| 3 | System Local Notifications (Notification setup, alerts, triggers) | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 4 | Barcode Scanning & OpenFoodFacts API (API query, Cache-Aside, error/timeout handling) | ORIGINAL_REQUEST §R3 & §R4 | 5 | 5 | ✓ |

## Test Architecture
- **Test Runner**: Flutter Test runner (`flutter test`) via headless execution on Windows/macOS/Linux.
- **Pass/Fail Semantics**: All tests must execute with zero exceptions and exit code 0 (`All tests passed!`).
- **Dependencies**:
  - `flutter_test` (bundled SDK)
  - `sqflite_common_ffi` (native in-memory SQLite for headless execution)
  - `mocktail` (declarative mock objects)
  - `http` (`package:http/testing.dart` for deterministic OpenFoodFacts HTTP simulation)
- **Directory Layout**:
```
test/
├── helpers/
│   ├── test_database_helper.dart       # In-memory SQLite FFI factory
│   ├── mock_notification_service.dart  # In-memory notification event recorder
│   ├── mock_off_client.dart            # MockClient response fixtures for OpenFoodFacts
│   └── test_app_wrapper.dart           # Widget pump helper with MultiProvider
├── tier1_feature_coverage/
│   ├── auth_coverage_test.dart         # 5 tests
│   ├── search_coverage_test.dart       # 5 tests
│   ├── notification_coverage_test.dart # 5 tests
│   └── scan_off_coverage_test.dart     # 5 tests
├── tier2_boundaries_corners/
│   ├── auth_boundary_test.dart         # 5 tests
│   ├── search_boundary_test.dart       # 5 tests
│   ├── notification_boundary_test.dart # 5 tests
│   └── scan_off_boundary_test.dart     # 5 tests
├── tier3_cross_feature/
│   └── cross_feature_test.dart         # 4 pairwise tests
└── tier4_real_world_scenarios/
    └── real_world_scenarios_test.dart  # 5 multi-step workflow tests
```

## Detailed Test Case Matrix

### Tier 1: Feature Coverage (20 tests)
- `T1_AUTH_01`: Successful user registration with valid email, password, and name persists to database.
- `T1_AUTH_02`: Successful user login with matching credentials yields authenticated `User` session.
- `T1_AUTH_03`: Login attempt with incorrect password fails and leaves session unauthenticated.
- `T1_AUTH_04`: Session persistence returns active user, and `logout()` clears session state.
- `T1_AUTH_05`: Registration fails when email already exists in `users` table (duplicate rejection).
- `T1_SEARCH_01`: Querying exact product name returns corresponding `CachedProduct` from SQLite.
- `T1_SEARCH_02`: Querying partial name ("yến mạch") returns multiple matching cached products.
- `T1_SEARCH_03`: Querying exact numeric barcode returns matched product record.
- `T1_SEARCH_04`: Querying brand name ("Mộc Hạt", "An Mộc") correctly filters products.
- `T1_SEARCH_05`: Querying non-existent keyword returns empty list (`[]`) without error.
- `T1_NOTIF_01`: Notification service initializes cleanly with `food_alerts` and `app_events` channels.
- `T1_NOTIF_02`: User login event triggers welcome notification on `app_events` channel.
- `T1_NOTIF_03`: User registration event triggers welcome notification on `app_events` channel.
- `T1_NOTIF_04`: Scan result with allergen violation triggers high-priority alert on `food_alerts` channel.
- `T1_NOTIF_05`: Safe scan evaluation dispatches informational notification on `app_events`.
- `T1_OFF_01`: OpenFoodFacts client parses 200 OK JSON response into `CachedProduct` and `ProductNutrition`.
- `T1_OFF_02`: OpenFoodFacts client handles product not found (404 / `status: 0`) and returns not-found signal.
- `T1_OFF_03`: OpenFoodFacts client handles network timeout/SocketException and returns error status.
- `T1_OFF_04`: `ProductRepository` performs Cache-Aside: fetches from API on cache miss and writes to SQLite.
- `T1_OFF_05`: Barcode input validator accepts valid EAN-13, EAN-8, and UPC-A formats.

### Tier 2: Boundary & Corner Cases (20 tests)
- `T2_AUTH_01`: Email input with leading/trailing spaces and uppercase characters is normalized before query.
- `T2_AUTH_02`: Password length boundary: exactly 6 characters succeeds; 5 characters fails validation.
- `T2_AUTH_03`: Empty strings, whitespace-only strings, or null values fail form validation rules.
- `T2_AUTH_04`: Names with Vietnamese diacritics ("Nguyễn Văn A") and passwords with special characters (`P@ss#1!`) hash and persist accurately.
- `T2_AUTH_05`: Corrupted or tampered session token in storage falls back safely to unauthenticated state.
- `T2_SEARCH_01`: Search query is case-insensitive and handles Vietnamese accents gracefully.
- `T2_SEARCH_02`: SQL wildcard characters (`%`, `_`), quotes (`'`), and operators (`' OR '1'='1`) do not break query or leak data.
- `T2_SEARCH_03`: Extremely long search query (250+ characters) handles gracefully without memory overflow or database lock.
- `T2_SEARCH_04`: Query with leading/trailing whitespace (`"   cacao   "`) trims properly and finds matches.
- `T2_SEARCH_05`: Searching against an empty database returns empty list without throwing null-pointer exception.
- `T2_NOTIF_01`: Rapid consecutive notifications with identical ID overwrite rather than piling up memory leaks.
- `T2_NOTIF_02`: Extremely long notification text (1000+ chars ingredients) truncates without crashing notification payload.
- `T2_NOTIF_03`: Product violating multiple allergens simultaneously aggregates violations into a single readable notification.
- `T2_NOTIF_04`: Notification dispatched when system permission is denied does not throw unhandled exception.
- `T2_NOTIF_05`: Notification trigger during headless background state completes without UI thread binding dependency.
- `T2_OFF_01`: OpenFoodFacts API returns valid 200 HTTP code but corrupt non-JSON body: client catches format error cleanly.
- `T2_OFF_02`: API returns partial product data missing `nutriments`: flags `is_incomplete = 1` with `missing_fields` list.
- `T2_OFF_03`: Barcode length boundary check: rejects 7, 9, 11, and 15 digit inputs.
- `T2_OFF_04`: Cache-Aside SQLite insert failure (e.g. disk/lock issue) still returns fetched product to caller without crash.
- `T2_OFF_05`: Rapid double-tap on simulation chips triggers only one network lookup (debounce verification).

### Tier 3: Cross-Feature Combinations (4 tests)
- `T3_CROSS_01`: **Auth + Search**: Authenticated user with profile allergens searches local database; search results show warning indicators on allergen-matching items.
- `T3_CROSS_02`: **Scan + Cache-Aside + Notification**: User scans new barcode; product is fetched from OpenFoodFacts, cached into SQLite, evaluated against user profile, and triggers an allergen alert notification.
- `T3_CROSS_03`: **Offline Scan + Search Fallback**: App in simulated airplane mode checks local SQLite for previously scanned product and displays details without navigating to `LookupErrorPage`.
- `T3_CROSS_04`: **Auth + Scan + History Logging**: Authenticated user scans product; record is stored in `scan_history` referencing current user and product foreign key, and scan completion notification fires.

### Tier 4: Real-World Application Scenarios (5 tests)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | `T4_SCENARIO_01`: First-Time User Onboarding & Safe Product Scan | Auth, Profile, Scan, OFF API, Notification | Medium |
| 2 | `T4_SCENARIO_02`: Allergen Violation High-Risk Detection Journey | Auth, Profile Allergens, Scan, Rules Engine, Food Alerts Notification | High |
| 3 | `T4_SCENARIO_03`: Offline In-Store Shopping with Cache Fallback & Missing Item | Local DB Search, Offline Barcode Scan, Error Status Page, Retry Flow | High |
| 4 | `T4_SCENARIO_04`: Product Discovery & Cache Ingestion Cycle | Barcode Input, OpenFoodFacts Cache-Aside, SQLite Ingestion, Instant Local Search | Medium |
| 5 | `T4_SCENARIO_05`: Incomplete Nutritional Data & OCR Fallback Flow | OpenFoodFacts API, Incompleteness Rules, Warning Banner, Camera/OCR Transition | Medium |

## Coverage Thresholds
- Tier 1: 20 tests (5 per feature across 4 features)
- Tier 2: 20 tests (5 per feature across 4 features)
- Tier 3: 4 cross-feature interaction tests
- Tier 4: 5 realistic application scenario tests
- **Total Test Count**: 49 tests (Threshold: ≥44)
