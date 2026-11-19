import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:an_lanh/data/remote/open_food_facts_api.dart';

void main() {
  group('Tier 5 Adversarial: Network Timing & Failure Modes', () {
    test('T5_ADV_NET_01: Premature stream abort (TCP RST / truncated body)', () async {
      final abortingClient = MockClient((request) async {
        throw http.ClientException('Connection closed while receiving data');
      });

      final api = OpenFoodFactsApi(client: abortingClient);
      final response = await api.fetchProduct('8934567890123');

      expect(response.isSuccess, isFalse);
      expect(response.isNetworkError, isTrue);
      expect(response.product, isNull);
    });

    test('T5_ADV_NET_02: OpenFoodFacts rate limit (HTTP 429 Too Many Requests)', () async {
      final rateLimitedClient = MockClient((request) async {
        return http.Response(
          'Too Many Requests',
          429,
          headers: {
            'content-type': 'text/plain',
            'retry-after': '60',
          },
        );
      });

      final api = OpenFoodFactsApi(client: rateLimitedClient);
      final response = await api.fetchProduct('8934567890123');

      expect(response.isSuccess, isFalse);
      expect(response.isFormatError, isTrue);
      expect(response.errorMessage, contains('429'));
    });

    test('T5_ADV_NET_03: Upstream gateway failure (HTTP 502 Bad Gateway / 504 Timeout)', () async {
      final gatewayFailureClient = MockClient((request) async {
        return http.Response(
          '<html><body><h1>502 Bad Gateway</h1></body></html>',
          502,
          headers: {'content-type': 'text/html'},
        );
      });

      final api = OpenFoodFactsApi(client: gatewayFailureClient);
      final response = await api.fetchProduct('8934567890123');

      expect(response.isSuccess, isFalse);
      expect(response.isNetworkError, isTrue);
      expect(response.errorMessage, contains('502'));
    });

    test('T5_ADV_NET_04: In-flight network disconnection and immediate retry', () async {
      bool isDisconnected = true;

      final intermittentClient = MockClient((request) async {
        if (isDisconnected) {
          throw const SocketException('Connection lost');
        }
        return http.Response(
          jsonEncode({
            'status': 1,
            'code': '8934567890123',
            'product': {
              'product_name': 'Retry Biscuit',
              'nutriments': {'sugars_100g': 10},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = OpenFoodFactsApi(client: intermittentClient);

      // Attempt 1: Disconnected
      final res1 = await api.fetchProduct('8934567890123');
      expect(res1.isSuccess, isFalse);
      expect(res1.isNetworkError, isTrue);

      // Reconnect immediately
      isDisconnected = false;

      // Attempt 2: Re-attempt
      final res2 = await api.fetchProduct('8934567890123');
      expect(res2.isSuccess, isTrue);
      expect(res2.product, isNotNull);
      expect(res2.product!.productName, 'Retry Biscuit');
    });

    test('T5_ADV_NET_05: Massive concurrent lookups for distinct barcodes', () async {
      final multiBarcodeClient = MockClient((request) async {
        final uri = request.url.toString();
        final match = RegExp(r'/(\d{13})\.json').firstMatch(uri);
        final code = match?.group(1) ?? '0000000000000';

        return http.Response(
          jsonEncode({
            'status': 1,
            'code': code,
            'product': {
              'product_name': 'Product $code',
              'brands': 'Brand $code',
              'nutriments': {'sugars_100g': 5},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final api = OpenFoodFactsApi(client: multiBarcodeClient);

      final barcodes = List.generate(
        20,
        (i) => '8930000000${i.toString().padLeft(3, '0')}',
      );

      final futures = barcodes.map((code) => api.fetchProduct(code));
      final results = await Future.wait(futures);

      expect(results.length, 20);
      for (int i = 0; i < 20; ++i) {
        final res = results[i];
        expect(res.isSuccess, isTrue);
        expect(res.product?.productName, 'Product ${barcodes[i]}');
      }
    });
  });
}
