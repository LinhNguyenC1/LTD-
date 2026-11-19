import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import '../helpers/test_database_helper.dart';
import '../helpers/mock_off_client.dart';
import '../helpers/open_food_facts_client.dart';
import '../helpers/cache_aside_coordinator.dart';
import '../helpers/validators.dart';

void main() {
  late Database db;
  late ProductDao productDao;
  late NutritionDao nutritionDao;
  late MockOffClientTracker tracker;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: false);
    productDao = ProductDao();
    nutritionDao = NutritionDao();
    tracker = MockOffClientTracker();
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  group('Tier 2: Barcode Scan & OpenFoodFacts Boundary Cases', () {
    test('T2_OFF_01: OpenFoodFacts API returns valid 200 HTTP code but corrupt non-JSON body', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);

      final response = await offClient.fetchProduct(MockOffFixtures.corruptBarcode);

      expect(response.isSuccess, isFalse);
      expect(response.isFormatError, isTrue);
      expect(response.product, isNull);
      expect(response.errorMessage, isNotNull);
    });

    test('T2_OFF_02: API returns partial product data missing nutriments: flags is_incomplete = true with missing_fields', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);

      final response = await offClient.fetchProduct(MockOffFixtures.incompleteBarcode);

      expect(response.isSuccess, isTrue);
      expect(response.product, isNotNull);
      expect(response.product!.isIncomplete, isTrue);
      expect(response.product!.missingFields, contains('nutriments'));
      expect(response.product!.missingFields, contains('ingredients_text'));
    });

    test('T2_OFF_03: Barcode length boundary check: rejects 7, 9, 11, and 15 digit inputs', () {
      // Boundaries immediately below and above valid lengths
      expect(BarcodeValidator.isValid('1234567'), isFalse); // 7 digits
      expect(BarcodeValidator.isValid('12345678'), isTrue); // 8 digits (EAN-8)
      expect(BarcodeValidator.isValid('123456789'), isFalse); // 9 digits
      expect(BarcodeValidator.isValid('12345678901'), isFalse); // 11 digits
      expect(BarcodeValidator.isValid('123456789012'), isTrue); // 12 digits (UPC-A)
      expect(BarcodeValidator.isValid('1234567890123'), isTrue); // 13 digits (EAN-13)
      expect(BarcodeValidator.isValid('12345678901234'), isFalse); // 14 digits
      expect(BarcodeValidator.isValid('123456789012345'), isFalse); // 15 digits

      // Non-numeric strings
      expect(BarcodeValidator.isValid('893456789012a'), isFalse);
      expect(BarcodeValidator.isValid(''), isFalse);
      expect(BarcodeValidator.isValid(null), isFalse);
    });

    test('T2_OFF_04: Cache-Aside SQLite insert failure still returns fetched product without crash', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // Simulate catastrophic SQLite disk full or lock error during cache write
      coordinator.simulateInsertFailure = true;

      // Must complete without throwing and return the fetched product
      final product = await coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(product, isNotNull);
      expect(product!.productName, 'Nutella Bready');
      expect(coordinator.networkCallCount, 1);
    });

    test('T2_OFF_05: Rapid double-tap on simulation chips triggers only one network lookup (debounce)', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // Fire two concurrent lookup requests for the exact same uncached barcode
      final futures = await Future.wait([
        coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode),
        coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode),
      ]);

      expect(futures[0], isNotNull);
      expect(futures[1], isNotNull);
      expect(futures[0]!.productName, 'Nutella Bready');
      expect(futures[1]!.productName, 'Nutella Bready');

      // Debounce must ensure exactly 1 network request was initiated
      expect(coordinator.networkCallCount, 1);
      expect(tracker.requestCount, 1);
    });
  });
}
