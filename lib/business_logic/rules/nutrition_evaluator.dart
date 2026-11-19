class NutritionEvaluator {
  static num? _parseNum(dynamic val) {
    if (val == null) return null;
    if (val is num) {
      if (!val.toDouble().isFinite || val < 0) return null;
      return val;
    }
    if (val is String) {
      final clean = val.trim().replaceAll(',', '.');
      final parsed = num.tryParse(clean);
      if (parsed != null && parsed.toDouble().isFinite && parsed >= 0) {
        return parsed;
      }
      return null;
    }
    return null;
  }

  static List<String> evaluate({
    required Map<String, double> targets,
    required Map<String, dynamic> actualData,
  }) {
    final List<String> violations = [];

    targets.forEach((nutrient, limit) {
      if (!limit.isFinite || limit < 0) return;
      num? actualVal;
      if (actualData.containsKey(nutrient)) {
        actualVal = _parseNum(actualData[nutrient]);
      }
      if (actualVal == null && actualData.containsKey('${nutrient}_100g')) {
        actualVal = _parseNum(actualData['${nutrient}_100g']);
      }

      if (actualVal != null && actualVal.toDouble() > limit) {
        violations.add(
          'Lượng $nutrient (${actualVal}g) vượt ngưỡng cho phép (${limit}g)',
        );
      }
    });

    return violations;
  }
}
