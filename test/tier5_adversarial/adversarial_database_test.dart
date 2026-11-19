import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/history_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/scan_history_item.dart';
import '../helpers/cache_aside_coordinator.dart';
import '../helpers/mock_off_client.dart';
import '../helpers/open_food_facts_client.dart';
import '../helpers/test_database_helper.dart';

void main() {
  late Database db;
  late ProductDao productDao;
  late NutritionDao nutritionDao;
  late HistoryDao historyDao;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: false);
    productDao = ProductDao();
    nutritionDao = NutritionDao();
    historyDao = HistoryDao();
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  group('Tier 5 Adversarial: Database Concurrency, Integrity & Constraints', () {
    test('T5_ADV_DB_01: Concurrent barcode ingestion race condition', () async {
      final mockClient = createMockOffClient();
      final offClient = OpenFoodFactsClient(client: mockClient);
      final coordinator = CacheAsideCoordinator(
        productDao: productDao,
        nutritionDao: nutritionDao,
        offClient: offClient,
      );

      // 5 concurrent requests hitting SQLite at the exact same moment for uncached barcode
      final futures = List.generate(
        5,
        (_) => coordinator.getProductByBarcode(MockOffFixtures.nutellaBarcode),
      );

      final results = await Future.wait(futures);

      // All 5 must receive a valid non-null CachedProduct
      for (final product in results) {
        expect(product, isNotNull);
        expect(product?.barcode, MockOffFixtures.nutellaBarcode);
      }

      // SQLite must contain exactly 1 row for this barcode, zero duplicates
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cached_product WHERE barcode = ?',
        [MockOffFixtures.nutellaBarcode],
      );
      final count = Sqflite.firstIntValue(rows);
      expect(count, 1);
    });

    test('T5_ADV_DB_02: Split-write recovery on nutrition insertion crash', () async {
      // Simulate product inserted into cached_product with is_incomplete = 1, but no nutrition row
      final productId = await db.insert('cached_product', {
        'barcode': '8939999999999',
        'product_name': 'Orphan Product',
        'brand': 'Test Brand',
        'is_incomplete': 1,
        'missing_fields': jsonEncode(['nutriments']),
        'cached_at': DateTime.now().toIso8601String(),
      });

      // Product query must succeed cleanly
      final productMap = await productDao.getProductByBarcode('8939999999999');
      expect(productMap, isNotNull);

      final product = CachedProduct.fromMap(productMap!);
      expect(product.productName, 'Orphan Product');
      expect(product.isIncomplete, isTrue);

      // Nutrition lookup returns null safely without throwing DatabaseException or NPE
      final nutritionMap = await nutritionDao.getNutritionByProductId(productId);
      expect(nutritionMap, isNull);
    });

    test('T5_ADV_DB_03: High-concurrency scan history logging stress', () async {
      // Create parent product
      final productId = await db.insert('cached_product', {
        'barcode': '8938888888888',
        'product_name': 'Stress Concurrency Item',
        'cached_at': DateTime.now().toIso8601String(),
      });

      // 30 concurrent workers logging history simultaneously
      final futures = List.generate(30, (i) {
        return historyDao.insertHistoryItem(
          ScanHistoryItem(
            productId: productId,
            evaluationStatus: i % 2 == 0 ? 'SAFE' : 'VIOLATION',
            violationReasons: i % 2 == 0 ? null : 'Allergen violation reason $i',
            scannedAt: DateTime.now().toIso8601String(),
          ),
        );
      });

      final insertedIds = await Future.wait(futures);
      expect(insertedIds.length, 30);

      final countRows = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scan_history WHERE product_id = ?',
        [productId],
      );
      expect(Sqflite.firstIntValue(countRows), 30);
    });

    test('T5_ADV_DB_04: Foreign key cascading deletion stress', () async {
      // Seed product with nutrition and scan history entries
      final productId = await db.insert('cached_product', {
        'barcode': '8937777777777',
        'product_name': 'Cascade Target Item',
        'cached_at': DateTime.now().toIso8601String(),
      });

      await db.insert('product_nutrition', {
        'product_id': productId,
        'nutrition_data': jsonEncode({'sugars': 10}),
      });

      for (int i = 0; i < 5; ++i) {
        await db.insert('scan_history', {
          'product_id': productId,
          'evaluation_status': 'SAFE',
          'scanned_at': DateTime.now().toIso8601String(),
        });
      }

      // Verify records exist prior to deletion
      final nutBefore = await db.rawQuery(
        'SELECT COUNT(*) as count FROM product_nutrition WHERE product_id = ?',
        [productId],
      );
      final histBefore = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scan_history WHERE product_id = ?',
        [productId],
      );
      expect(Sqflite.firstIntValue(nutBefore), 1);
      expect(Sqflite.firstIntValue(histBefore), 5);

      // Delete parent product from cached_product
      final deletedCount = await db.delete(
        'cached_product',
        where: 'id = ?',
        whereArgs: [productId],
      );
      expect(deletedCount, 1);

      // PRAGMA foreign_keys = ON must cascade delete both nutrition and history rows
      final nutAfter = await db.rawQuery(
        'SELECT COUNT(*) as count FROM product_nutrition WHERE product_id = ?',
        [productId],
      );
      final histAfter = await db.rawQuery(
        'SELECT COUNT(*) as count FROM scan_history WHERE product_id = ?',
        [productId],
      );
      expect(Sqflite.firstIntValue(nutAfter), 0);
      expect(Sqflite.firstIntValue(histAfter), 0);
    });

    test('T5_ADV_DB_05: Foreign key violation rejection', () async {
      // Inserting history record pointing to non-existent product_id = 99999
      expect(
        () async => await db.insert('scan_history', {
          'product_id': 99999,
          'evaluation_status': 'SAFE',
          'scanned_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
