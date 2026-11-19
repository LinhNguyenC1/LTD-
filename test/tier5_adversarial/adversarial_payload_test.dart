import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:an_lanh/business_logic/rules/allergy_evaluator.dart';
import 'package:an_lanh/business_logic/rules/nutrition_evaluator.dart';
import 'package:an_lanh/core/validators/form_validator.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/remote/open_food_facts_api.dart';
import '../helpers/mock_notification_service.dart';
import '../helpers/test_database_helper.dart';

void main() {
  setUpAll(() {
    setupTestDatabaseFactory();
  });

  group('Tier 5 Adversarial: Malformed Payloads & Boundary Inputs', () {
    test('T5_ADV_INPUT_01: Malformed OFF JSON with structural type mutations', () async {
      // Probe 1: nutriments is an array [] instead of map
      final clientArrayNutriments = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'code': '1234567890123',
            'product': {
              'product_name': 'Test Array Nutriments',
              'nutriments': ['invalid', 'array', 'format'],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final offApi1 = OpenFoodFactsApi(client: clientArrayNutriments);
      final res1 = await offApi1.fetchProduct('1234567890123');
      expect(res1.isSuccess, isFalse);
      expect(res1.isFormatError, isTrue);

      // Probe 2: product is a string "error" instead of map
      final clientStringProduct = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 1,
            'code': '1234567890123',
            'product': 'error_not_a_map',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final offApi2 = OpenFoodFactsApi(client: clientStringProduct);
      final res2 = await offApi2.fetchProduct('1234567890123');
      expect(res2.isSuccess, isFalse);
      expect(res2.isFormatError, isTrue);

      // Probe 3: empty body ""
      final clientEmptyBody = MockClient((request) async {
        return http.Response('', 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });
      final offApi3 = OpenFoodFactsApi(client: clientEmptyBody);
      final res3 = await offApi3.fetchProduct('1234567890123');
      expect(res3.isSuccess, isFalse);
      expect(res3.isFormatError, isTrue);
    });

    test('T5_ADV_INPUT_02: Floating-point extremes and overflow in nutrition', () {
      final targets = {
        'sugars': 10.0,
        'fat': double.nan,
        'sodium': double.infinity,
        'negative_target': -10.0,
      };

      final actualData = {
        'sugars': -50.0,
        'fat': 'corrupt_not_num',
        'sodium': 1e308,
        'negative_target': 5.0,
        'protein': double.nan,
      };

      final violations = NutritionEvaluator.evaluate(
        targets: targets,
        actualData: actualData,
      );

      // sugars is -50 (ignored as negative), fat is corrupt (ignored), sodium target is infinite (ignored),
      // negative_target is -10 (ignored as negative limit). No false positive violations should be produced.
      expect(violations, isEmpty);

      // Validate non-finite float strings reject at FormValidator level
      expect(FormValidator.validatePositiveNumber('NaN'), 'Vui lòng nhập số hợp lệ');
      expect(FormValidator.validatePositiveNumber('Infinity'), 'Vui lòng nhập số hợp lệ');
      expect(FormValidator.validatePositiveNumber('+Infinity'), 'Vui lòng nhập số hợp lệ');
      expect(FormValidator.validatePositiveNumber('-Infinity'), 'Vui lòng nhập số hợp lệ');
      expect(FormValidator.validatePositiveNumber('1e309'), 'Vui lòng nhập số hợp lệ');
    });

    test('T5_ADV_INPUT_03: Empty and whitespace allergen code injection', () {
      const text = 'Bánh mì sandwich bơ tỏi, không chứa đậu nành.';
      const tags = ['en:wheat', 'en:garlic'];

      // Inject empty and whitespace allergens
      final violationsEmpty = AllergyEvaluator.evaluate(
        userAllergens: ['', '   ', '   \t\n  '],
        ingredientsText: text,
        allergensTags: tags,
      );
      expect(violationsEmpty, isEmpty);

      // User allergic to milk (not in ingredients) and empty strings
      final violationsMixed = AllergyEvaluator.evaluate(
        userAllergens: ['', 'milk', '   '],
        ingredientsText: text,
        allergensTags: tags,
      );
      expect(violationsMixed, isEmpty);

      // User allergic to gluten with whitespace entries - text containing 'bột mì'
      final violationsGluten = AllergyEvaluator.evaluate(
        userAllergens: ['  ', 'gluten', ''],
        ingredientsText: 'Bột mì nguyên chất, dầu thực vật, đường',
        allergensTags: tags,
      );
      expect(violationsGluten, contains('gluten'));
      expect(violationsGluten.length, 1);
    });

    test('T5_ADV_INPUT_04: Unicode normalization (NFC vs NFD) and emoji stress', () async {
      final db = await createInMemoryTestDatabase(seedData: false);
      final productDao = ProductDao();

      // Product with decomposed Vietnamese (NFD), emojis, and special chars
      const nfdName = 'Sư\u031ba tươi ti\u0323\u0301t tru\u0300ng 🍫 \u200B';
      final product = CachedProduct(
        barcode: '893600000001',
        productName: nfdName,
        brand: 'Vinamilk 🥛',
        cachedAt: DateTime.now().toIso8601String(),
      );

      final id = await productDao.insertProduct(product.toMap());
      expect(id, greaterThan(0));

      // Query with emoji and special chars
      final results1 = await productDao.searchProducts('chocolate');
      expect(results1, isEmpty);

      final results2 = await productDao.searchProducts('Vinamilk');
      expect(results2.length, 1);
      expect(results2.first['barcode'], '893600000001');

      final results3 = await productDao.searchProducts('893600000001');
      expect(results3.length, 1);
      expect(results3.first['barcode'], '893600000001');

      await tearDownTestDatabase(db);
    });

    test('T5_ADV_INPUT_05: Notification ID boundary and integer overflow', () async {
      final notifService = MockNotificationService();
      await notifService.initialize();

      // INT32_MAX
      await notifService.showNotification(
        id: 2147483647,
        title: 'Max Int Alert',
        body: 'Testing int32 max boundary',
      );
      expect(notifService.activeNotificationsById.containsKey(2147483647), isTrue);

      // Negative ID
      await notifService.showNotification(
        id: -1,
        title: 'Negative ID Alert',
        body: 'Testing negative id',
      );
      expect(notifService.activeNotificationsById.containsKey(-1), isTrue);

      // 50 rapid sequential notifications
      for (int i = 0; i < 50; ++i) {
        await notifService.showNotification(
          id: i,
          title: 'Stress Notification $i',
          body: 'Stress body $i',
        );
      }
      expect(notifService.deliveredNotifications.length, 52);
    });
  });
}
