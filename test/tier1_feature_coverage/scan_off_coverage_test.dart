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

  group('Tier 1: Barcode Scan & OpenFoodFacts Coverage Tests', () {
    test('T1_OFF_01: OpenFoodFacts client parses 200 OK JSON response into CachedProduct and ProductNutrition', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);

      final response = await offClient.fetchProduct(MockOffFixtures.nutellaBarcode);

      expect(response.isSuccess, isTrue);
      expect(response.product, isNotNull);
      expect(response.product!.productName, 'Nutella Bready');
      expect(response.product!.brand, 'Ferrero');
      expect(response.product!.barcode, MockOffFixtures.nutellaBarcode);
      expect(response.product!.nutriscoreGrade, 'e');

      expect(response.nutrition, isNotNull);
      final nutriments = response.nutrition!.nutritionData;
      expect(nutriments['sugars_100g'], 47.1);
      expect(nutriments['fat_100g'], 28.2);
    });

    test('T1_OFF_02: OpenFoodFacts client handles product not found (404 / status: 0)', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);

      final response = await offClient.fetchProduct(MockOffFixtures.notFoundBarcode);

      expect(response.isSuccess, isFalse);
      expect(response.isNotFound, isTrue);
      expect(response.product, isNull);
      expect(response.errorMessage, isNotNull);
    });

    test('T1_OFF_03: OpenFoodFacts client handles network timeout/SocketException and returns error status', () async {
      tracker.simulateSocketError = true;
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);

      final response = await offClient.fetchProduct(MockOffFixtures.nutellaBarcode);

      expect(response.isSuccess, isFalse);
      expect(response.isNetworkError, isTrue);
      expect(response.product, isNull);
    });

    test('T1_OFF_04: ProductRepository performs Cache-Aside: fetches from API on cache miss and writes to SQLite', () async {
      final mockClient = createMockOffClient(tracker: tracker);
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // Verify barcode is not in SQLite initially
      final initialCheck = await productDao.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(initialCheck, isNull);

      // Cache miss -> fetch from MockClient -> persist to SQLite
      final fetched = await coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(fetched, isNotNull);
      expect(fetched!.productName, 'Nutella Bready');
      expect(coordinator.networkCallCount, 1);

      // Verify now present in SQLite
      final dbRow = await productDao.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(dbRow, isNotNull);
      expect(dbRow!['product_name'], 'Nutella Bready');

      // Verify nutrition table also populated
      final nutRow = await nutritionDao.getNutritionByProductId(dbRow['id'] as int);
      expect(nutRow, isNotNull);

      // Subsequent query: Cache hit -> returns directly from SQLite without network call
      final cachedHit = await coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode);
      expect(cachedHit, isNotNull);
      expect(cachedHit!.productName, 'Nutella Bready');
      expect(coordinator.networkCallCount, 1); // call count remains 1!
    });

    test('T1_OFF_05: Barcode input validator accepts valid EAN-13, EAN-8, and UPC-A formats', () {
      // EAN-13: 13 digits
      expect(BarcodeValidator.isValid('8934567890123'), isTrue);
      expect(BarcodeValidator.isValid('3017620422003'), isTrue);

      // EAN-8: 8 digits
      expect(BarcodeValidator.isValid('12345670'), isTrue);

      // UPC-A: 12 digits
      expect(BarcodeValidator.isValid('012345678905'), isTrue);
    });
  });
}
