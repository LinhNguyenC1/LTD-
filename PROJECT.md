# Project: Ăn Lành (LTD-) - Personalized Food Assistant

## Architecture
- **Presentation Layer** (`lib/presentation/`):
  - Screens:
    - Auth: `lib/presentation/screens/auth/login_page.dart`, `lib/presentation/screens/auth/register_page.dart`
    - Home & Search: `lib/presentation/screens/home/home_page.dart`, `lib/presentation/screens/home/search_page.dart`
    - Scan & Lookups: `lib/presentation/screens/scan/scan_page.dart`, `lookup_error_page.dart`, `lookup_not_found_page.dart`
    - Product Details & Compare: `lib/presentation/screens/product/detail_page.dart`, `lib/presentation/screens/compare/`
    - Profile: `lib/presentation/screens/profile/profile_page.dart`
    - History: `lib/presentation/screens/history/history_page.dart`
  - Reusable Widgets: `pack_widget.dart`, `status_badge.dart`, `custom_bottom_nav.dart`
- **Business Logic Layer** (`lib/business_logic/`):
  - ViewModels (`ChangeNotifier` via `provider`):
    - `auth_viewmodel.dart`: Manages login, registration, session state, input validation
    - `profile_viewmodel.dart`: Manages health profile, allergens, dynamic nutrient targets
    - `scan_viewmodel.dart`: Manages barcode scanning, manual input, OpenFoodFacts query, caching, evaluation
    - `search_viewmodel.dart`: Manages local database product search and filtering
    - `history_viewmodel.dart`: Manages scan history and filtering
  - Rules Engine:
    - `allergy_evaluator.dart`: Matches allergen codes against product ingredients
    - `nutrition_evaluator.dart`: Compares product nutrients with user threshold targets
    - `completeness_checker.dart`: Checks required fields and flags incomplete data
- **Data Layer** (`lib/data/`):
  - Local Storage (`sqflite` on `an_lanh.db`):
    - Helper: `lib/data/local/db_helper.dart` (tables: `users`, `user_profile`, `user_allergen`, `cached_product`, `product_nutrition`, `scan_history`)
    - DAOs: `user_dao.dart`, `profile_dao.dart`, `product_dao.dart`, `nutrition_dao.dart`, `history_dao.dart`
  - Remote Services:
    - `lib/data/remote/open_food_facts_api.dart`: REST client for OpenFoodFacts API v2
    - `lib/core/services/notification_service.dart`: Cross-platform local notification service
  - Repositories:
    - `auth_repository.dart`: Coordinates user authentication and session persistence
    - `profile_repository.dart`: Coordinates profile and allergen persistence
    - `product_repository.dart`: Cache-Aside coordinator between OpenFoodFacts API and SQLite
- **Core / Utilities** (`lib/core/`):
  - Constants: `api_constants.dart`, `app_theme.dart`
  - Validators: `barcode_validator.dart`, `form_validator.dart`

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Database Schema Expansion | Add users table, foreign keys, unique constraint on product_nutrition, performance indexes | M1 | PDF Spec §2 & Survey 1 |
| 2 | Product & Nutrition DAOs | Implement ProductDao, NutritionDao, UserDao for full relational SQLite persistence | M1 | Survey 1 & Survey 2 |
| 3 | User Authentication Logic | Local account creation, login authentication, password hash/check, session state | M2 | R1 Acceptance Criteria |
| 4 | Auth Screens (Login & Register) | Clean UI with form validation, email regex, password min-length, confirm match | M2 | R1 & R4 |
| 5 | Product Search from Database | Search bar filtering products from SQLite cached_product by name, barcode, brand | M2 | R1 Acceptance Criteria |
| 6 | System Notification Setup | Configure flutter_local_notifications with Android channels (food_alerts, app_events) and desktop fallback | M3 | R2 Acceptance Criteria |
| 7 | Notification Triggers | Fire notifications on login/register success, critical allergen violations, and scan completion | M3 | R2 & Survey 3 |
| 8 | OpenFoodFacts API Client | REST client v2 with User-Agent header, field filtering (?fields=...), 10s timeout, JSON mapping | M4 | R3 & Survey 3 |
| 9 | Cache-Aside Product Ingestion | Look up SQLite first; if missing, fetch from OpenFoodFacts; save to cached_product & product_nutrition | M4 | PDF Spec §1 & Survey 3 |
| 10 | Barcode Input & Hardware Fallback | Manual numeric keypad input, 1-tap fast simulation test chips (Coca-Cola, Nutella, Bánh cacao, 404 test), and camera integration | M4 | R3 & Survey 3 |
| 11 | Error Handling & Status Pages | Route 404/not found to LookupNotFoundPage, route offline/timeout to LookupErrorPage with friendly retry | M4 | R4 & Survey 3 |
| 12 | Form Validation Hardening | TextFormField validators on ProfilePage (non-empty name, numeric targets) and Auth forms | M5 | R4 & Survey 3 |
| 13 | Comprehensive Test Suite | Unit tests for DAOs, OpenFoodFacts API mock, Auth, ViewModels, and Widget tests | M5 / Dual Track | R4 Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Database & DAOs Layer | SQLite schema expansion (users table, unique constraints, 3 indexes), UserDao, ProductDao, NutritionDao, ProductRepository | None | DONE |
| M2 | Auth & Search Integration | Login/Register screens, AuthViewModel, SearchViewModel, product search querying SQLite, input validation | M1 | DONE |
| M3 | System Local Notifications | flutter_local_notifications integration, NotificationService, AndroidManifest permissions, app event triggers | M1, M2 | DONE |
| M4 | OpenFoodFacts API & Barcode Scanning | OpenFoodFacts API v2 client, manual barcode input & test chips, Cache-Aside caching, DetailPage integration, error pages routing | M1, M3 | DONE |
| M5 | Form Validation, Hardening & Independent Tests | Profile form validators, end-to-end integration verification, unit & widget test suites | M1, M2, M3, M4 | DONE |

## Interface Contracts
### Data Layer ↔ Business Logic Layer
- `AuthRepository`:
  - `Future<bool> register(String email, String password, String name)`
  - `Future<User?> login(String email, String password)`
  - `Future<User?> getCurrentUser()`
  - `Future<void> logout()`
- `ProductRepository`:
  - `Future<CachedProduct?> getProductByBarcode(String barcode)`
  - `Future<CachedProduct> fetchAndCacheFromApi(String barcode)`
  - `Future<List<CachedProduct>> searchProducts(String query)`
  - `Future<ProductNutrition?> getNutritionByProductId(int productId)`
- `NotificationService`:
  - `Future<void> initialize()`
  - `Future<void> showNotification({required int id, required String title, required String body, String? channelId})`
  - `Future<void> showAllergenAlert({required String productName, required String allergenName})`
- `OpenFoodFactsApi`:
  - `Future<ApiResponse<CachedProduct>> fetchProduct(String barcode)`

## Code Layout
- `lib/core/`: Application-wide utilities, theme, constants, services
- `lib/data/local/`: SQLite helper, DAOs, local database operations
- `lib/data/remote/`: External API clients (OpenFoodFacts)
- `lib/data/models/`: Entity models
- `lib/data/repositories/`: Repository implementations
- `lib/business_logic/`: ViewModels and evaluation rules engine
- `lib/presentation/`: UI screens and custom widgets
- `test/`: Unit tests, widget tests, and integration test fixtures
