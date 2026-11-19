class AllergyEvaluator {
  static final Map<String, List<String>> allergenKeywords = {
    'milk': ['sữa', 'bột sữa', 'milk', 'whey', 'casein', 'lactose', 'en:milk'],
    'peanut': ['đậu phộng', 'lạc', 'peanut', 'peanuts', 'en:peanuts'],
    'soy': ['đậu nành', 'đậu tương', 'soy', 'soybean', 'lecithin đậu nành', 'en:soybeans'],
    'gluten': ['gluten', 'bột mì', 'lúa mì', 'yến mạch', 'wheat', 'oat', 'en:gluten'],
    'egg': ['trứng', 'egg', 'eggs', 'en:eggs'],
    'nuts': ['hạt dẻ', 'hạnh nhân', 'noisettes', 'nuts', 'en:nuts'],
  };

  static List<String> evaluate({
    required List<String> userAllergens,
    required String? ingredientsText,
    List<String>? allergensTags,
  }) {
    if (userAllergens.isEmpty) return [];

    final text = (ingredientsText ?? '').toLowerCase();
    final tags = (allergensTags ?? []).map((t) => t.toLowerCase()).toList();

    final List<String> violations = [];

    for (final allergen in userAllergens) {
      final code = allergen.toLowerCase().trim();
      if (code.isEmpty) continue;
      final rawKeywords = allergenKeywords[code] ?? [code];
      final keywords = rawKeywords.where((kw) => kw.trim().isNotEmpty).toList();
      if (keywords.isEmpty) continue;

      bool found = false;
      for (final kw in keywords) {
        if (text.contains(kw) || tags.contains(kw)) {
          found = true;
          break;
        }
      }

      if (found) {
        violations.add(allergen);
      }
    }

    return violations;
  }
}
