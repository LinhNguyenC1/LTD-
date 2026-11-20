import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:an_lanh/core/services/ai_service.dart';

void main() {
	group('AiService Unit Tests', () {
		setUp(() {
			AiService.userApiKey = '';
		});

		tearDown(() {
			AiService.userApiKey = 'AIzaSyC1sae0YW8_ol3EFCH-J_krwISZxS28DVA';
		});

		test('returns offline parser result when no API key is provided', () async {
			final res = await AiService.analyzeNote('Tôi dị ứng sữa và đậu phộng');

			expect(res.isFromCloudAi, isFalse);
			expect(res.providerName, contains('Offline'));
			expect(res.criteria.length, 2);
			expect(res.criteria.any((c) => c.allergenKey == 'milk'), isTrue);
			expect(res.criteria.any((c) => c.allergenKey == 'peanut'), isTrue);
		});

		test('parses Gemini API JSON response successfully on HTTP 200', () async {
			const mockGeminiResponse = {
				'candidates': [
					{
						'content': {
							'parts': [
								{
									'text': '''
{
  "allergens": [
    {"key": "shrimp", "title": "Dị ứng tôm", "quote": "tôm"},
    {"key": "egg", "title": "Dị ứng trứng", "quote": "trứng gà"}
  ],
  "nutrition": [
    {"key": "sugars", "title": "Hạn chế đường", "limit": 5.0, "quote": "ít đường"}
  ]
}
'''
								}
							]
						}
					}
				]
			};

			final mockClient = MockClient((request) async {
				expect(request.url.toString(), contains('generativelanguage.googleapis.com'));
				return http.Response(jsonEncode(mockGeminiResponse), 200, headers: {'content-type': 'application/json'});
			});

			final res = await AiService.analyzeNote(
				'Tôi bị dị ứng tôm và trứng gà, muốn ăn ít đường',
				client: mockClient,
				customApiKey: 'test-fake-api-key',
			);

			expect(res.isFromCloudAi, isTrue);
			expect(res.providerName, contains('Gemini'));
			expect(res.criteria.length, 3);
			expect(res.criteria.any((c) => c.allergenKey == 'shrimp'), isTrue);
			expect(res.criteria.any((c) => c.allergenKey == 'egg'), isTrue);
			expect(res.criteria.any((c) => c.nutritionKey == 'sugars' && c.targetValue == 5.0), isTrue);
		});

		test('falls back to local parser when Gemini API returns HTTP 500 error', () async {
			final mockClient = MockClient((request) async {
				return http.Response('Internal Server Error', 500);
			});

			final res = await AiService.analyzeNote(
				'Dị ứng sữa',
				client: mockClient,
				customApiKey: 'test-key',
			);

			expect(res.isFromCloudAi, isFalse);
			expect(res.providerName, contains('Offline'));
			expect(res.criteria.any((c) => c.allergenKey == 'milk'), isTrue);
		});
	});
}
