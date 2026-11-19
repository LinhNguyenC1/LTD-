import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/local/db_helper.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late ProductDao productDao;
  late NutritionDao nutritionDao;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    await createInMemoryTestDatabase(seedData: false);
    productDao = ProductDao();
    nutritionDao = NutritionDao();
  });

  tearDown(() async {
    await DatabaseHelper.reset();
  });

  group('NutritionDao Tests', () {
    test('insertOrUpdateNutrition inserts nutrition for existing product', () async {
      final now = DateTime.now().toIso8601String();
      final pId = await productDao.insertProduct({
        'barcode': '8935000000001',
        'product_name': 'Nước cam ép Vfresh',
        'cached_at': now,
      });

      final nutId = await nutritionDao.insertOrUpdateNutrition({
        'product_id': pId,
        'nutrition_data': jsonEncode({
          'energy_kcal': 45,
          'sugars': 9.8,
          'sodium': 0.01,
        }),
      });

      expect(nutId, greaterThan(0));

      final retrieved = await nutritionDao.getNutritionByProductId(pId);
      expect(retrieved, isNotNull);
      expect(retrieved!['product_id'], pId);

      final decoded = jsonDecode(retrieved['nutrition_data'] as String);
      expect(decoded['sugars'], 9.8);
      expect(decoded['energy_kcal'], 45);
    });

    test('getNutritionByProductId returns null when product has no nutrition', () async {
      final res = await nutritionDao.getNutritionByProductId(99999);
      expect(res, isNull);
    });

    test('insertOrUpdateNutrition updates existing nutrition without duplicating row',
        () async {
      final now = DateTime.now().toIso8601String();
      final pId = await productDao.insertProduct({
        'barcode': '8935000000002',
        'product_name': 'Sữa đậu nành Fami',
        'cached_at': now,
      });

      final id1 = await nutritionDao.insertOrUpdateNutrition({
        'product_id': pId,
        'nutrition_data': jsonEncode({'sugars': 8.0, 'protein': 3.1}),
      });

      // Update with new data
      final id2 = await nutritionDao.insertOrUpdateNutrition({
        'product_id': pId,
        'nutrition_data': jsonEncode({'sugars': 7.5, 'protein': 3.3}),
      });

      expect(id2, equals(id1));

      final updated = await nutritionDao.getNutritionByProductId(pId);
      expect(updated, isNotNull);
      final decoded = jsonDecode(updated!['nutrition_data'] as String);
      expect(decoded['sugars'], 7.5);
      expect(decoded['protein'], 3.3);
    });

    test('deleteNutritionByProductId removes record', () async {
      final now = DateTime.now().toIso8601String();
      final pId = await productDao.insertProduct({
        'barcode': '8935000000003',
        'product_name': 'Bánh cracker AFC',
        'cached_at': now,
      });

      await nutritionDao.insertOrUpdateNutrition({
        'product_id': pId,
        'nutrition_data': jsonEncode({'energy_kcal': 490}),
      });

      final count = await nutritionDao.deleteNutritionByProductId(pId);
      expect(count, 1);

      final retrieved = await nutritionDao.getNutritionByProductId(pId);
      expect(retrieved, isNull);
    });

    test('foreign key failure when inserting nutrition for non-existent product', () async {
      expect(
        () async => await nutritionDao.insertOrUpdateNutrition({
          'product_id': 999999,
          'nutrition_data': jsonEncode({'sugars': 0}),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
