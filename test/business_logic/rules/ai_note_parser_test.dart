import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/business_logic/rules/ai_note_parser.dart';

void main() {
	group('AiNoteParser Unit Tests', () {
		test('parses single allergen correctly without false positives', () {
			final res = AiNoteParser.parse('Tôi dị ứng đậu phộng');
			expect(res.length, 1);
			expect(res.first.id, 'allergen_peanut');
			expect(res.first.title, 'Dị ứng đậu phộng');
			expect(res.first.type, 'allergen');
			expect(res.any((c) => c.allergenKey == 'milk'), isFalse);
			expect(res.any((c) => c.nutritionKey == 'sugars'), isFalse);
		});

		test('parses multi-criteria note with allergens and nutrition limits', () {
			const note = 'Tôi dị ứng sữa và đậu phộng, muốn giảm đường và muối';
			final res = AiNoteParser.parse(note);

			expect(res.length, 4);
			expect(res.any((c) => c.allergenKey == 'milk'), isTrue);
			expect(res.any((c) => c.allergenKey == 'peanut'), isTrue);
			expect(res.any((c) => c.nutritionKey == 'sugars'), isTrue);
			expect(res.any((c) => c.nutritionKey == 'sodium'), isTrue);
		});

		test('parses custom numerical values for nutrition thresholds', () {
			const note = 'Cần kiêng đường 5g và muối 0.2g, đạm 20g';
			final res = AiNoteParser.parse(note);

			final sugar = res.firstWhere((c) => c.nutritionKey == 'sugars');
			expect(sugar.targetValue, 5.0);

			final sodium = res.firstWhere((c) => c.nutritionKey == 'sodium');
			expect(sodium.targetValue, 0.2);

			final protein = res.firstWhere((c) => c.nutritionKey == 'protein_min');
			expect(protein.targetValue, 20.0);
		});

		test('parses seafood and egg allergies accurately', () {
			const note = 'Bị dị ứng tôm và trứng gà';
			final res = AiNoteParser.parse(note);

			expect(res.any((c) => c.allergenKey == 'shrimp'), isTrue);
			expect(res.any((c) => c.allergenKey == 'egg'), isTrue);
		});

		test('returns fallback custom note when no keywords match', () {
			final res = AiNoteParser.parse('Một lối sống lành mạnh');
			expect(res.length, 1);
			expect(res.first.type, 'custom');
			expect(res.first.id, 'custom_note');
		});

		test('returns empty list when input is empty string', () {
			final res = AiNoteParser.parse('   ');
			expect(res, isEmpty);
		});
	});
}
