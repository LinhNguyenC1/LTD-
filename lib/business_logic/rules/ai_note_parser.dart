class ExtractedCriterion {
	final String id;
	final String title;
	final String subtitle;
	final String quote;
	final String type; // 'diet', 'allergen', 'nutrition', 'custom'
	final String? allergenKey;
	final String? nutritionKey;
	final double? targetValue;
	bool isSelected;

	ExtractedCriterion({
		required this.id,
		required this.title,
		required this.subtitle,
		required this.quote,
		required this.type,
		this.allergenKey,
		this.nutritionKey,
		this.targetValue,
		this.isSelected = true,
	});

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'title': title,
			'subtitle': subtitle,
			'quote': quote,
			'type': type,
			'allergenKey': allergenKey,
			'nutritionKey': nutritionKey,
			'targetValue': targetValue,
			'isSelected': isSelected,
		};
	}
}

class AiNoteParser {
	static String _normalize(String input) {
		var str = input.toLowerCase();
		const withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
		const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
		for (int i = 0; i < withDiacritics.length; i++) {
			str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
		}
		return str;
	}

	static bool _containsWord(String text, String kw) {
		final pattern = RegExp(
			r'(^|[^\p{L}\p{N}])' + RegExp.escape(kw) + r'([^\p{L}\p{N}]|$)',
			unicode: true,
			caseSensitive: false,
		);
		return pattern.hasMatch(text);
	}

	static String _extractSnippet(String originalText, List<String> patterns) {
		for (final p in patterns) {
			final idx = originalText.toLowerCase().indexOf(p.toLowerCase());
			if (idx != -1) {
				final start = idx > 15 ? originalText.lastIndexOf(' ', idx - 1) : 0;
				final safeStart = start == -1 ? 0 : start;
				final end = (idx + p.length + 15 < originalText.length)
						? originalText.indexOf(' ', idx + p.length + 1)
						: originalText.length;
				final safeEnd = end == -1 ? originalText.length : end;
				final snippet = originalText.substring(safeStart, safeEnd).trim();
				return snippet.isNotEmpty ? snippet : p;
			}
		}
		return patterns.first;
	}

	static double? _extractNumberNear(String text, String keyword) {
		final norm = _normalize(text);
		final normKw = _normalize(keyword);
		final kwIdx = norm.indexOf(normKw);
		if (kwIdx == -1) return null;

		final numRegex = RegExp(r'(\d+([.,]\d+)?)');

		// 1. Look forward first (e.g. "đường 5g", "muối 0.2g")
		final afterStart = kwIdx + normKw.length;
		final afterEnd = (afterStart + 25 < text.length) ? afterStart + 25 : text.length;
		final forwardWindow = text.substring(afterStart, afterEnd);
		final fMatch = numRegex.firstMatch(forwardWindow);
		if (fMatch != null) {
			return double.tryParse(fMatch.group(1)!.replaceAll(',', '.'));
		}

		// 2. Look backward (e.g. "dưới 5g đường")
		final beforeStart = kwIdx > 25 ? kwIdx - 25 : 0;
		final backwardWindow = text.substring(beforeStart, kwIdx);
		final bMatches = numRegex.allMatches(backwardWindow);
		if (bMatches.isNotEmpty) {
			return double.tryParse(bMatches.last.group(1)!.replaceAll(',', '.'));
		}

		return null;
	}

	static List<ExtractedCriterion> parse(String noteText) {
		final trimmed = noteText.trim();
		if (trimmed.isEmpty) return [];

		final norm = _normalize(trimmed);
		final List<ExtractedCriterion> list = [];

		// 1. Dietary Focus
		if (_containsWord(norm, 'keto') || norm.contains('low carb') || norm.contains('lowcarb')) {
			list.add(ExtractedCriterion(
				id: 'diet_keto',
				title: 'Chế độ ăn Keto / Low-Carb',
				subtitle: 'Hạn chế tối đa tinh bột và đường, tăng chất béo tốt',
				quote: _extractSnippet(trimmed, ['keto', 'low carb', 'lowcarb']),
				type: 'diet',
			));
		}

		// 2. Allergens
		final allergenDefs = [
			{
				'key': 'milk',
				'title': 'Dị ứng sữa',
				'subtitle': 'Đã nhận diện · Tránh sữa, lactose, bột sữa và bơ',
				'keywords': ['sữa', 'sua', 'lactose', 'bột sữa', 'bo sua', 'milk'],
			},
			{
				'key': 'peanut',
				'title': 'Dị ứng đậu phộng',
				'subtitle': 'Đã nhận diện · Tránh đậu phộng, lạc và dầu phộng',
				'keywords': ['đậu phộng', 'dau phong', 'lạc', 'peanut'],
			},
			{
				'key': 'gluten',
				'title': 'Dị ứng gluten',
				'subtitle': 'Đã nhận diện · Tránh lúa mì, lúa mạch, bột mì',
				'keywords': ['gluten', 'bột mì', 'bot mi', 'lúa mì', 'lua mi', 'wheat'],
			},
			{
				'key': 'soy',
				'title': 'Dị ứng đậu nành',
				'subtitle': 'Đã nhận diện · Tránh đậu nành, đậu tương, lecithin',
				'keywords': ['đậu nành', 'dau nanh', 'đậu tương', 'dau tuong', 'soy', 'tofu', 'đậu hũ', 'dau hu'],
			},
			{
				'key': 'egg',
				'title': 'Dị ứng trứng',
				'subtitle': 'Đã nhận diện · Tránh trứng gà, trứng vịt, albumin',
				'keywords': ['trứng', 'trung', 'egg'],
			},
			{
				'key': 'seafood',
				'title': 'Dị ứng hải sản',
				'subtitle': 'Đã nhận diện · Tránh nghêu, sò, ốc, mực, hải sản vỏ cứng',
				'keywords': ['hải sản', 'hai san', 'seafood', 'nghêu', 'ngheu', 'sò', 'so', 'ốc', 'oc', 'mực', 'muc'],
			},
			{
				'key': 'shrimp',
				'title': 'Dị ứng tôm / tép',
				'subtitle': 'Đã nhận diện · Tránh tôm, tép, tôm khô',
				'keywords': ['tôm', 'tom', 'tép', 'tep', 'shrimp', 'prawn'],
			},
			{
				'key': 'crab',
				'title': 'Dị ứng cua / ghẹ',
				'subtitle': 'Đã nhận diện · Tránh cua biển, cua đồng, ghẹ',
				'keywords': ['cua', 'ghẹ', 'ghe', 'crab'],
			},
			{
				'key': 'fish',
				'title': 'Dị ứng cá biển',
				'subtitle': 'Đã nhận diện · Tránh cá hồi, cá ngừ, cá biển, dầu cá',
				'keywords': ['cá biển', 'ca bien', 'cá hồi', 'ca hoi', 'cá ngừ', 'ca ngu', 'cá', 'ca', 'fish'],
			},
			{
				'key': 'sesame',
				'title': 'Dị ứng mè / vừng',
				'subtitle': 'Đã nhận diện · Tránh mè, vừng, dầu mè',
				'keywords': ['mè', 'me', 'vừng', 'vung', 'sesame'],
			},
			{
				'key': 'chili',
				'title': 'Tránh đồ cay / Ớt',
				'subtitle': 'Đã nhận diện · Tránh ớt, capsaicin, thực phẩm cay nóng',
				'keywords': ['ớt', 'ot', 'cay', 'capsaicin', 'chili'],
			},
			{
				'key': 'msg',
				'title': 'Không dùng bột ngọt / MSG',
				'subtitle': 'Đã nhận diện · Tránh mì chính, bột ngọt, phụ gia MSG',
				'keywords': ['bột ngọt', 'bot ngot', 'mì chính', 'mi chinh', 'msg', 'ajinomoto'],
			},
			{
				'key': 'beef',
				'title': 'Tránh thịt bò',
				'subtitle': 'Đã nhận diện · Tránh các sản phẩm từ thịt bò',
				'keywords': ['thịt bò', 'thit bo', 'beef'],
			},
		];

		for (final def in allergenDefs) {
			final kws = def['keywords'] as List<String>;
			bool matched = false;
			String matchedKw = '';
			for (final kw in kws) {
				final normKw = _normalize(kw);
				if (_containsWord(norm, normKw)) {
					matched = true;
					matchedKw = kw;
					break;
				}
			}
			if (matched) {
				list.add(ExtractedCriterion(
					id: 'allergen_${def['key']}',
					title: def['title'] as String,
					subtitle: def['subtitle'] as String,
					quote: _extractSnippet(trimmed, [matchedKw, ...kws]),
					type: 'allergen',
					allergenKey: def['key'] as String,
				));
			}
		}

		// 3. Nutrition Targets
		final nutritionDefs = [
			{
				'key': 'sugars',
				'title': 'Hạn chế đường',
				'keywords': ['đường', 'duong', 'ngọt', 'ngot', 'sugar', 'tiểu đường', 'tieu duong'],
				'default': 10.0,
				'unit': 'g/100 g',
				'prefix': '≤',
			},
			{
				'key': 'sodium',
				'title': 'Hạn chế muối / Natri',
				'keywords': ['muối', 'muoi', 'mặn', 'man', 'natri', 'salt', 'sodium', 'huyết áp', 'huyet ap'],
				'default': 0.30,
				'unit': 'g/100 g',
				'prefix': '≤',
			},
			{
				'key': 'total_fat',
				'title': 'Hạn chế chất béo',
				'keywords': ['chất béo', 'chat beo', 'dầu mỡ', 'dau mo', 'mỡ máu', 'mo mau', 'lipid', 'béo', 'beo'],
				'default': 10.0,
				'unit': 'g/100 g',
				'prefix': '≤',
			},
			{
				'key': 'protein_min',
				'title': 'Bổ sung chất đạm',
				'keywords': ['đạm', 'dam', 'protein', 'tăng cơ', 'tang co', 'gym'],
				'default': 15.0,
				'unit': 'g/100 g',
				'prefix': '≥',
			},
			{
				'key': 'calories',
				'title': 'Kiểm soát Calo / Năng lượng',
				'keywords': ['calo', 'calori', 'năng lượng', 'nang luong', 'giảm cân', 'giam can', 'béo phì', 'energy'],
				'default': 200.0,
				'unit': 'kcal/100 g',
				'prefix': '≤',
			},
			{
				'key': 'fiber',
				'title': 'Bổ sung chất xơ',
				'keywords': ['chất xơ', 'chat xo', 'tiêu hóa', 'tieu hoa', 'fiber'],
				'default': 5.0,
				'unit': 'g/100 g',
				'prefix': '≥',
			},
		];

		for (final def in nutritionDefs) {
			final kws = def['keywords'] as List<String>;
			bool matched = false;
			String matchedKw = '';
			for (final kw in kws) {
				final normKw = _normalize(kw);
				if (_containsWord(norm, normKw)) {
					matched = true;
					matchedKw = kw;
					break;
				}
			}
			if (matched) {
				final defaultVal = def['default'] as double;
				final parsedVal = _extractNumberNear(trimmed, matchedKw) ?? defaultVal;
				final unit = def['unit'] as String;
				final prefix = def['prefix'] as String;

				list.add(ExtractedCriterion(
					id: 'nutrition_${def['key']}',
					title: def['title'] as String,
					subtitle: 'Mức AI gợi ý: $prefix $parsedVal $unit',
					quote: _extractSnippet(trimmed, [matchedKw, ...kws]),
					type: 'nutrition',
					nutritionKey: def['key'] as String,
					targetValue: parsedVal,
				));
			}
		}

		// 4. Fallback if no specific criteria matched
		if (list.isEmpty) {
			list.add(ExtractedCriterion(
				id: 'custom_note',
				title: 'Ghi chú ăn uống riêng',
				subtitle: 'Lưu vào ghi chú cá nhân để hỗ trợ theo dõi thực phẩm',
				quote: trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed,
				type: 'custom',
			));
		}

		return list;
	}
}
