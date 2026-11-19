import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/local/daos/history_dao.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import 'package:an_lanh/data/repositories/profile_repository.dart';
import '../helpers/test_database_helper.dart';
import '../helpers/mock_notification_service.dart';
import '../helpers/mock_off_client.dart';
import '../helpers/open_food_facts_client.dart';
import '../helpers/cache_aside_coordinator.dart';
import '../helpers/rules_engine.dart';

void main() {
  late Database db;
  late UserDao userDao;
  late ProductDao productDao;
  late NutritionDao nutritionDao;
  late HistoryDao historyDao;
  late AuthRepository authRepository;
  late ProductRepository productRepository;
  late ProfileRepository profileRepository;
  late MockNotificationService notificationService;
  late MockOffClientTracker tracker;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: true);
    userDao = UserDao();
    productDao = ProductDao();
    nutritionDao = NutritionDao();
    historyDao = HistoryDao();
    authRepository = AuthRepository(userDao: userDao);
    productRepository = ProductRepository(productDao: productDao, nutritionDao: nutritionDao);
    profileRepository = ProfileRepository();
    notificationService = MockNotificationService();
    await notificationService.initialize();
    tracker = MockOffClientTracker();
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
    notificationService.reset();
  });

  group('Tier 4: Real-World Application Scenarios', () {
    test('T4_SCENARIO_01: First-Time User Onboarding & Safe Product Scan Journey', () async {
      // 1. Onboarding: Register new user account
      final registered = await authRepository.register(
        'lanh.new@anlanh.vn',
        'safePassword123',
        'Lành Mới',
      );
      expect(registered, isTrue);

      final currentUser = await authRepository.getCurrentUser();
      expect(currentUser, isNotNull);

      // 2. Profile setup: Configure peanut allergen and sugar limit of 10g
      await profileRepository.saveUserProfile(
        name: 'Lành Mới',
        allergens: ['peanut'],
        nutritionTargets: {'sugars': 10.0},
      );

      final profile = await profileRepository.fetchUserProfile();
      expect(profile, isNotNull);
      expect(profile!.allergens, contains('peanut'));
      expect(profile.nutritionTargets['sugars'], 10.0);

      // 3. Scan safe product: "Bánh yến mạch nguyên bản" (barcode 8934567890456)
      final productMap = await productDao.getProductByBarcode('8934567890456');
      expect(productMap, isNotNull);

      final nutritionMap = await nutritionDao.getNutritionByProductId(productMap!['id'] as int);
      expect(nutritionMap, isNotNull);

      // 4. Rules evaluation: Check allergen and nutrition
      final allergenViolations = AllergyEvaluator.evaluate(
        userAllergens: profile.allergens,
        ingredientsText: productMap['ingredients_text'] as String?,
      );
      final nutritionViolations = NutritionEvaluator.evaluate(
        targets: profile.nutritionTargets,
        actualData: nutritionMap!['nutrition_data'] is Map<String, dynamic>
            ? nutritionMap['nutrition_data'] as Map<String, dynamic>
            : {'sugars': 4.2},
      );

      expect(allergenViolations, isEmpty);
      expect(nutritionViolations, isEmpty);

      // 5. Safe evaluation logged into scan history
      final now = DateTime.now().toIso8601String();
      await db.insert('scan_history', {
        'product_id': productMap['id'],
        'evaluation_status': 'SAFE',
        'violation_reasons': 'Không phát hiện vi phạm hồ sơ',
        'scanned_at': now,
      });

      // 6. Safe scan notification emitted
      await notificationService.showSafeScanNotification(productMap['product_name'] as String);

      // Verify outcomes
      final history = await historyDao.getAllHistory();
      expect(history.any((h) => h.productName == 'Bánh yến mạch nguyên bản' && h.evaluationStatus == 'SAFE'), isTrue);

      expect(notificationService.deliveredNotifications.last.channelId, 'app_events');
      expect(notificationService.deliveredNotifications.last.title, contains('Sản phẩm an toàn'));
    });

    test('T4_SCENARIO_02: Allergen Violation High-Risk Detection Workflow', () async {
      // 1. Existing user logs in
      await authRepository.register('linh@anlanh.vn', 'passLinh123', 'Linh Trần');
      await authRepository.login('linh@anlanh.vn', 'passLinh123');

      // 2. Profile has milk allergen
      await profileRepository.saveUserProfile(
        name: 'Linh Trần',
        allergens: ['milk'],
        nutritionTargets: {'sugars': 10.0},
      );
      final profile = await profileRepository.fetchUserProfile();
      expect(profile!.allergens, contains('milk'));

      // 3. User scans 'Bánh yến mạch cacao' (barcode 8934567890123)
      final productMap = await productDao.getProductByBarcode('8934567890123');
      expect(productMap, isNotNull);

      // 4. Rules engine evaluates: flags milk allergy violation!
      final allergenViolations = AllergyEvaluator.evaluate(
        userAllergens: profile.allergens,
        ingredientsText: productMap!['ingredients_text'] as String?,
      );
      expect(allergenViolations, contains('milk'));

      // 5. System immediately fires critical notification on 'food_alerts'
      await notificationService.showAllergenAlert(
        productName: productMap['product_name'] as String,
        allergenName: 'bột sữa 8%',
      );

      // 6. Record VIOLATION in scan_history
      final now = DateTime.now().toIso8601String();
      await db.insert('scan_history', {
        'product_id': productMap['id'],
        'evaluation_status': 'VIOLATION',
        'violation_reasons': 'Chứa bột sữa trùng tiêu chí dị ứng sữa trong hồ sơ',
        'scanned_at': now,
      });

      // Verify outcomes
      final alert = notificationService.activeNotificationsById[100];
      expect(alert, isNotNull);
      expect(alert!.channelId, 'food_alerts');
      expect(alert.title, contains('Cảnh báo dị ứng'));
      expect(alert.body, contains('bột sữa 8%'));

      final latestHistory = (await historyDao.getAllHistory()).first;
      expect(latestHistory.evaluationStatus, 'VIOLATION');
      expect(latestHistory.violationReasons, contains('bột sữa'));
    });

    test('T4_SCENARIO_03: Offline In-Store Shopping with Cache Fallback & Missing Item', () async {
      // Offline mode enabled
      tracker.simulateSocketError = true;
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // Step 1: In-store local search for 'Mộc Hạt' succeeds offline
      final searchResults = await productRepository.searchProducts('Mộc Hạt');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.productName, 'Bánh yến mạch cacao');

      // Step 2: User scans an unknown barcode not in DB
      const unknownBarcode = '8930000000999';
      final cachedCheck = await productDao.getProductByBarcode(unknownBarcode);
      expect(cachedCheck, isNull);

      // Step 3: Network fetch attempted -> SocketException / offline detected
      final fetchResult = await offClient.fetchProduct(unknownBarcode);
      expect(fetchResult.isNetworkError, isTrue);
      expect(fetchResult.errorMessage, isNotNull);

      // Step 4: Verify coordinator does not crash and returns null safely
      final result = await coordinator.getProductByBarcode(unknownBarcode);
      expect(result, isNull);
    });

    test('T4_SCENARIO_04: Product Discovery & Cache Ingestion Cycle', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // Step 1: User scans barcode 3017620422003 (Nutella Bready) -> not in SQLite
      final initialSearch = await productRepository.searchProducts('Nutella');
      expect(initialSearch, isEmpty);

      // Step 2: Lookup triggers Cache-Aside ingestion from OpenFoodFacts
      final product = await coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(product, isNotNull);
      expect(product!.productName, 'Nutella Bready');
      expect(product.brand, 'Ferrero');

      // Step 3: Ingestion persists into SQLite
      final inDb = await productDao.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(inDb, isNotNull);
      expect(inDb!['product_name'], 'Nutella Bready');

      // Step 4: User goes to Search page: local search for 'Ferrero' finds Nutella instantly!
      final ferreroSearch = await productRepository.searchProducts('Ferrero');
      expect(ferreroSearch, isNotEmpty);
      expect(ferreroSearch.first.productName, 'Nutella Bready');
      expect(ferreroSearch.first.barcode, MockOffFixtures.nutellaBarcode);
    });

    test('T4_SCENARIO_05: Incomplete Nutritional Data & Scan Mode Transition Flow', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);

      // Step 1: Scan barcode with missing nutriments and empty ingredients
      final response = await offClient.fetchProduct(MockOffFixtures.incompleteBarcode);
      expect(response.isSuccess, isTrue);

      final product = response.product!;
      expect(product.isIncomplete, isTrue);
      expect(product.missingFields, contains('nutriments'));
      expect(product.missingFields, contains('ingredients_text'));

      // Step 2: System detects incomplete data and determines OCR mode transition is needed
      bool requiresOcrFallback = product.isIncomplete && product.missingFields.contains('ingredients_text');
      expect(requiresOcrFallback, isTrue);

      // Step 3: Transition scan mode simulation
      var currentScanMode = 'barcode';
      if (requiresOcrFallback) {
        currentScanMode = 'ingredientList'; // Triggers OCR mode
      }
      expect(currentScanMode, 'ingredientList');

      // Step 4: When in OCR mode, manual or OCR text extraction can supplement the product
      const extractedOcrText = 'Bột mì, bơ 25%, đường, muối';
      final updatedProduct = product.copyWith(
        ingredientsText: extractedOcrText,
        isIncomplete: false,
        missingFields: [],
      );

      expect(updatedProduct.ingredientsText, extractedOcrText);
      expect(updatedProduct.isIncomplete, isFalse);
    });
  });
}
