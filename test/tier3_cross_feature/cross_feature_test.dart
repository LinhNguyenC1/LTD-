import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/local/daos/history_dao.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
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
    notificationService = MockNotificationService();
    await notificationService.initialize();
    tracker = MockOffClientTracker();
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
    notificationService.reset();
  });

  group('Tier 3: Cross-Feature Interaction Tests', () {
    test('T3_CROSS_01: Auth + Search: Authenticated user with profile allergens searches local DB; matching items flagged with warning', () async {
      // 1. Authenticate user
      final loggedIn = await authRepository.register(
        'allergen_user@anlanh.vn',
        'safePass123',
        'User Dị Ứng',
      );
      expect(loggedIn, isTrue);

      // 2. User profile has 'milk' allergen configured
      final userAllergens = ['milk'];

      // 3. User searches database for 'yến mạch'
      final searchResults = await productRepository.searchProducts('yến mạch');
      expect(searchResults.length, greaterThanOrEqualTo(2));

      // 4. Evaluate each product against user allergens
      final evaluatedItems = searchResults.map((product) {
        final violations = AllergyEvaluator.evaluate(
          userAllergens: userAllergens,
          ingredientsText: product.ingredientsText,
        );
        return {
          'product': product,
          'hasAllergenWarning': violations.isNotEmpty,
          'violations': violations,
        };
      }).toList();

      // 'Bánh yến mạch cacao' contains milk -> must have allergen warning
      final cacaoItem = evaluatedItems.firstWhere(
        (item) => (item['product'] as dynamic).productName == 'Bánh yến mạch cacao',
      );
      expect(cacaoItem['hasAllergenWarning'], isTrue);
      expect(cacaoItem['violations'] as List<String>, contains('milk'));

      // 'Bánh yến mạch nguyên bản' does not contain milk -> no warning
      final originalItem = evaluatedItems.firstWhere(
        (item) => (item['product'] as dynamic).productName == 'Bánh yến mạch nguyên bản',
      );
      expect(originalItem['hasAllergenWarning'], isFalse);
      expect(originalItem['violations'] as List<String>, isEmpty);
    });

    test('T3_CROSS_02: Scan + Cache-Aside + Notification: Scanned barcode fetched, cached, and allergen alert triggered', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // User profile allergens
      final userAllergens = ['milk', 'nuts'];

      // 1. Scan new barcode (Nutella)
      final scannedProduct = await coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(scannedProduct, isNotNull);
      expect(scannedProduct!.productName, 'Nutella Bready');

      // 2. Verify product is cached in SQLite
      final cached = await productDao.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(cached, isNotNull);

      // 3. Rules engine evaluates product ingredients
      final detectedAllergens = AllergyEvaluator.evaluate(
        userAllergens: userAllergens,
        ingredientsText: scannedProduct.ingredientsText,
      );
      expect(detectedAllergens, isNotEmpty);

      // 4. Notification service emits allergen alert
      for (final allergen in detectedAllergens) {
        await notificationService.showAllergenAlert(
          productName: scannedProduct.productName,
          allergenName: allergen,
        );
      }

      expect(notificationService.deliveredNotifications, isNotEmpty);
      final alert = notificationService.deliveredNotifications.first;
      expect(alert.channelId, 'food_alerts');
      expect(alert.title, contains('Nutella Bready'));
      expect(alert.title, contains('Cảnh báo dị ứng'));
    });

    test('T3_CROSS_03: Offline Scan + Search Fallback: Simulated airplane mode uses local cache without error page', () async {
      // Simulate airplane mode / offline by forcing network socket failure
      tracker.simulateSocketError = true;
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // 1. Query previously seeded product '8934567890123'
      const cachedBarcode = '8934567890123';
      final product = await coordinator.getProductByBarcode(cachedBarcode);

      // 2. Cache hit returns product directly from SQLite without attempting network
      expect(product, isNotNull);
      expect(product!.productName, 'Bánh yến mạch cacao');
      expect(coordinator.networkCallCount, 0); // zero network calls in offline mode!
    });

    test('T3_CROSS_04: Auth + Scan + History Logging: Authenticated user scan logs to scan_history with foreign key and emits notification', () async {
      // 1. Authenticate user
      await authRepository.register('history_user@anlanh.vn', 'pass123456', 'History Tester');
      final currentUser = await authRepository.getCurrentUser();
      expect(currentUser, isNotNull);

      // 2. User scans seeded product '8934567890456'
      const barcode = '8934567890456';
      final productMap = await productDao.getProductByBarcode(barcode);
      expect(productMap, isNotNull);
      final productId = productMap!['id'] as int;

      // 3. Log scan event into scan_history table
      final now = DateTime.now().toIso8601String();
      await db.insert('scan_history', {
        'product_id': productId,
        'evaluation_status': 'SAFE',
        'violation_reasons': 'Đủ dữ liệu, không ghi nhận vi phạm tiêu chí trong hồ sơ.',
        'scanned_at': now,
      });

      // 4. Notification service emits scan completed event
      await notificationService.showScanCompletedNotification('Bánh yến mạch nguyên bản');

      // 5. Verify scan history record via HistoryDao
      final allHistory = await historyDao.getAllHistory();
      expect(allHistory, isNotEmpty);
      final latest = allHistory.first;
      expect(latest.productId, productId);
      expect(latest.productName, 'Bánh yến mạch nguyên bản');
      expect(latest.evaluationStatus, 'SAFE');

      // Verify notification recorded
      final notif = notificationService.deliveredNotifications.last;
      expect(notif.channelId, 'app_events');
      expect(notif.title, contains('Đã quét'));
      expect(notif.body, contains('lịch sử'));
    });
  });
}
