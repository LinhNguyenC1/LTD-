import '../../data/models/cached_product.dart';
import '../../data/models/product_nutrition.dart';

class CompletenessResult {
  final bool isIncomplete;
  final List<String> missingFields;

  const CompletenessResult({
    required this.isIncomplete,
    required this.missingFields,
  });
}

class CompletenessChecker {
  static CompletenessResult check(
    CachedProduct product, [
    ProductNutrition? nutrition,
  ]) {
    final List<String> missing = [];

    if (product.ingredientsText == null ||
        product.ingredientsText!.trim().isEmpty) {
      missing.add('ingredients_text');
    }

    if (nutrition == null || nutrition.nutritionData.isEmpty) {
      missing.add('nutriments');
    }

    return CompletenessResult(
      isIncomplete: missing.isNotEmpty,
      missingFields: missing,
    );
  }
}
