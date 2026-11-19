import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:an_lanh/data/remote/open_food_facts_api.dart';
import 'package:an_lanh/core/constants/api_constants.dart';

void main() {
  group('OpenFoodFactsApi Remote Client Tests', () {
    test('returns formatError when barcode is empty or whitespace', () async {
      final api = OpenFoodFactsApi();
      final res1 = await api.fetchProduct('');
      expect(res1.isFormatError, isTrue);
      expect(res1.errorMessage, contains('Mã vạch không được để trống'));

      final res2 = await api.fetchProduct('   ');
      expect(res2.isFormatError, isTrue);
    });

    test('parses 200 OK valid product with complete nutriments and fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'world.openfoodfacts.org');
        expect(request.url.path, '${ApiConstants.productEndpoint}/3017620422003.json');
        expect(request.headers['User-Agent'], ApiConstants.userAgentHeader);
        expect(request.headers['Accept'], ApiConstants.acceptHeader);

        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Nutella B-ready',
            'brands': 'Ferrero',
            'image_url': 'https://images.openfoodfacts.org/nutella.jpg',
            'ingredients_text': 'Đường, dầu cọ, hạt dẻ 13%, sữa bột tách kem 8.7%, cacao',
            'serving_size': '22 g',
            'nutriscore_grade': 'e',
            'nutriments': {
              'energy-kcal_100g': 521,
              'fat_100g': 27.0,
              'saturated-fat_100g': 9.5,
              'sugars_100g': 45.4,
              'proteins_100g': 7.2,
              'salt_100g': 0.53,
              'sodium_100g': 0.21,
            },
          },
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('3017620422003');

      expect(response.isSuccess, isTrue);
      expect(response.product, isNotNull);
      final product = response.product!;
      expect(product.barcode, '3017620422003');
      expect(product.productName, 'Nutella B-ready');
      expect(product.brand, 'Ferrero');
      expect(product.imageUrl, 'https://images.openfoodfacts.org/nutella.jpg');
      expect(product.servingSize, '22 g');
      expect(product.nutriscoreGrade, 'e');
      expect(product.isIncomplete, isFalse);
      expect(product.missingFields, isEmpty);

      expect(response.nutrition, isNotNull);
      final nutriments = response.nutrition!.nutritionData;
      // Standard 100g keys
      expect(nutriments['sugars_100g'], 45.4);
      expect(nutriments['fat_100g'], 27.0);
      expect(nutriments['energy-kcal_100g'], 521);
      // Normalized short keys
      expect(nutriments['sugars'], 45.4);
      expect(nutriments['fat'], 27.0);
      expect(nutriments['energy_kcal'], 521);
      expect(nutriments['saturated_fat'], 9.5);
      expect(nutriments['protein'], 7.2);
      expect(nutriments['salt'], 0.53);
      expect(nutriments['sodium'], 0.21);
    });

    test('returns notFound when HTTP 404 is returned', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('0000000000000');

      expect(response.isNotFound, isTrue);
      expect(response.isSuccess, isFalse);
      expect(response.product, isNull);
    });

    test('returns notFound when API status is 0 or product is null', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': 0,
          'status_verbose': 'product not found',
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('9999999999999');

      expect(response.isNotFound, isTrue);
      expect(response.product, isNull);
    });

    test('returns formatError on non-JSON response body', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html><body>502 Bad Gateway</body></html>', 200,
            headers: {'content-type': 'text/html'});
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('8934567890123');

      expect(response.isFormatError, isTrue);
      expect(response.errorMessage, isNotNull);
    });

    test('detects missing fields and marks isIncomplete = true', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Sản phẩm thiếu thành phần',
            // No ingredients_text, no nutriments
          },
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('8930001112223');

      expect(response.isSuccess, isTrue);
      expect(response.product, isNotNull);
      expect(response.product!.isIncomplete, isTrue);
      expect(response.product!.missingFields, contains('ingredients_text'));
      expect(response.product!.missingFields, contains('nutriments'));
      expect(response.nutrition, isNull);
    });

    test('returns networkError on ClientException or network failure', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('8934567890123');

      expect(response.isNetworkError, isTrue);
      expect(response.isSuccess, isFalse);
    });

    test('handles image_front_url and ingredients_text_vi fallbacks', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Bánh Mì Việt Nam',
            'image_front_url': 'https://images.openfoodfacts.org/front.jpg',
            'ingredients_text_vi': 'Bột mì, men, nước, muối',
            'nutriments': {'sugars': 2.0},
          },
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('8938888888888');

      expect(response.isSuccess, isTrue);
      expect(response.product!.imageUrl, 'https://images.openfoodfacts.org/front.jpg');
      expect(response.product!.ingredientsText, 'Bột mì, men, nước, muối');
      expect(response.product!.isIncomplete, isFalse);
    });

    test('returns networkError when server responds with HTTP 500/502/503 even with JSON body', () async {
      for (final code in [500, 502, 503]) {
        final mockClient = MockClient((request) async {
          final body = jsonEncode({
            'status': 0,
            'status_verbose': 'server error',
            'error': 'Internal server error',
          });
          return http.Response(body, code, headers: {'content-type': 'application/json'});
        });

        final api = OpenFoodFactsApi(client: mockClient);
        final response = await api.fetchProduct('8934567890123');

        expect(response.isNetworkError, isTrue, reason: 'HTTP $code should be classified as networkError');
        expect(response.isNotFound, isFalse);
        expect(response.errorMessage, contains('$code'));
      }
    });

    test('returns formatError when server responds with HTTP 400 or 403 with JSON body', () async {
      for (final code in [400, 403]) {
        final mockClient = MockClient((request) async {
          final body = jsonEncode({
            'status': 0,
            'error': 'Bad Request or Forbidden',
          });
          return http.Response(body, code, headers: {'content-type': 'application/json'});
        });

        final api = OpenFoodFactsApi(client: mockClient);
        final response = await api.fetchProduct('8934567890123');

        expect(response.isFormatError, isTrue, reason: 'HTTP $code should be classified as formatError');
        expect(response.isNotFound, isFalse);
      }
    });

    test('normalizes string-formatted nutrient numbers to num in nutriments', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'String Nutrients Product',
            'ingredients_text': 'Đường, Bột',
            'nutriments': {
              'sugars_100g': '15.5',
              'fat_100g': '8.2',
              'energy-kcal_100g': '250',
            },
          },
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final api = OpenFoodFactsApi(client: mockClient);
      final response = await api.fetchProduct('8931112223334');

      expect(response.isSuccess, isTrue);
      expect(response.nutrition, isNotNull);
      final data = response.nutrition!.nutritionData;
      expect(data['sugars_100g'], 15.5);
      expect(data['fat_100g'], 8.2);
      expect(data['energy-kcal_100g'], 250);
      expect(data['sugars'], 15.5);
      expect(data['fat'], 8.2);
    });
  });
}
