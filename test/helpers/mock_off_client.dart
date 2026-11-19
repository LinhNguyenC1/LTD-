import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockOffFixtures {
  static const String nutellaBarcode = '3017620422003';
  static const String cacaoBiscuitBarcode = '8934567890123';
  static const String originalBiscuitBarcode = '8934567890456';
  static const String incompleteBarcode = '7622210449283';
  static const String notFoundBarcode = '0000000000000';
  static const String corruptBarcode = '9999999999999';

  static String nutellaJson = jsonEncode({
    'status': 1,
    'status_verbose': 'product found',
    'code': nutellaBarcode,
    'product': {
      'product_name': 'Nutella Bready',
      'brands': 'Ferrero',
      'image_url': 'https://images.openfoodfacts.org/images/products/301/762/042/2003/front_fr.jpg',
      'ingredients_text': 'Pâte à tartiner aux noisettes et au cacao 81,5% (sucre, huile de palme, noisettes 13%, lait écrémé en poudre 8,7%, cacao maigre 7,4%, émulsifiants: lécithines de soja, vanilline), farine de froment 16%, levure de bière, extrait de malt d\'orge, sel, lait écrémé en poudre.',
      'serving_size': '22g',
      'nutriscore_grade': 'e',
      'allergens_tags': [
        'en:gluten',
        'en:milk',
        'en:nuts',
        'en:soybeans',
      ],
      'nutriments': {
        'energy-kcal_100g': 521,
        'fat_100g': 28.2,
        'saturated-fat_100g': 9.5,
        'carbohydrates_100g': 60.7,
        'sugars_100g': 47.1,
        'proteins_100g': 7.2,
        'salt_100g': 0.52,
        'sodium_100g': 0.208,
      },
    },
  });

  static String cacaoBiscuitJson = jsonEncode({
    'status': 1,
    'status_verbose': 'product found',
    'code': cacaoBiscuitBarcode,
    'product': {
      'product_name': 'Bánh yến mạch cacao',
      'brands': 'Mộc Hạt',
      'image_url': 'https://example.com/cacao.jpg',
      'ingredients_text': 'Yến mạch 45%, bột mì, đường, dầu cọ, bột sữa 8%, cacao 4%, lecithin đậu nành, muối',
      'serving_size': '100g',
      'nutriscore_grade': 'c',
      'allergens_tags': ['en:milk', 'en:gluten', 'en:soybeans'],
      'nutriments': {
        'energy-kcal_100g': 450,
        'fat_100g': 16.5,
        'saturated-fat_100g': 7.2,
        'carbohydrates_100g': 64.0,
        'sugars_100g': 18.0,
        'proteins_100g': 7.5,
        'salt_100g': 1.05,
        'sodium_100g': 0.42,
      },
    },
  });

  static String incompleteProductJson = jsonEncode({
    'status': 1,
    'status_verbose': 'product found',
    'code': incompleteBarcode,
    'product': {
      'product_name': 'Bánh quy bơ thiếu dinh dưỡng',
      'brands': 'Danisa',
      'image_url': 'https://example.com/danisa.jpg',
      'ingredients_text': '',
      'serving_size': '50g',
      'nutriscore_grade': null,
      'allergens_tags': <String>[],
      'nutriments': <String, dynamic>{},
    },
  });

  static String notFoundJson = jsonEncode({
    'status': 0,
    'status_verbose': 'product not found',
    'code': notFoundBarcode,
  });

  static const String corruptNonJson =
      '<html><head><title>502 Bad Gateway</title></head><body><h1>Server Down</h1></body></html>';
}

class MockOffClientTracker {
  int requestCount = 0;
  final List<String> requestedUrls = [];
  bool simulateTimeout = false;
  bool simulateSocketError = false;

  void reset() {
    requestCount = 0;
    requestedUrls.clear();
    simulateTimeout = false;
    simulateSocketError = false;
  }
}

MockClient createMockOffClient({
  MockOffClientTracker? tracker,
}) {
  return MockClient((http.Request request) async {
    tracker?.requestCount++;
    tracker?.requestedUrls.add(request.url.toString());

    if (tracker?.simulateTimeout == true) {
      throw const SocketException('Simulated network timeout connection failure');
    }
    if (tracker?.simulateSocketError == true) {
      throw const SocketException('No address associated with hostname');
    }

    final url = request.url.toString();

    if (url.contains(MockOffFixtures.nutellaBarcode)) {
      return http.Response(
        MockOffFixtures.nutellaJson,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    if (url.contains(MockOffFixtures.cacaoBiscuitBarcode)) {
      return http.Response(
        MockOffFixtures.cacaoBiscuitJson,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    if (url.contains(MockOffFixtures.incompleteBarcode)) {
      return http.Response(
        MockOffFixtures.incompleteProductJson,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    if (url.contains(MockOffFixtures.corruptBarcode)) {
      return http.Response(
        MockOffFixtures.corruptNonJson,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    }

    if (url.contains(MockOffFixtures.notFoundBarcode)) {
      return http.Response(
        MockOffFixtures.notFoundJson,
        404,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    // Default: return 404 product not found
    return http.Response(
      MockOffFixtures.notFoundJson,
      404,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}
