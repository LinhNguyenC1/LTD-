import 'cached_product.dart';
import 'food.dart';
import 'product_nutrition.dart';

extension CachedProductAdapter on CachedProduct {
  Food toFood({
    ProductNutrition? nutrition,
    List<String> allergenViolations = const [],
    List<String> nutritionViolations = const [],
  }) {
    final grade = nutriscoreGrade?.toLowerCase();
    final String tone;
    final Result res;

    if (allergenViolations.isNotEmpty) {
      res = Result.bad;
      tone = 'gold';
    } else if (nutritionViolations.isNotEmpty) {
      res = Result.warn;
      tone = 'brown';
    } else if (isIncomplete) {
      res = Result.unknown;
      tone = 'slate';
    } else if (grade == 'a' || grade == 'b') {
      res = Result.good;
      tone = 'green';
    } else if (grade == 'c') {
      res = Result.warn;
      tone = 'brown';
    } else if (grade == 'd' || grade == 'e') {
      res = Result.bad;
      tone = 'gold';
    } else {
      res = Result.good;
      tone = 'slate';
    }

    String formatMetric(List<String> keys, String unit) {
      final data = nutrition?.nutritionData;
      if (data == null) return 'Chưa có dữ liệu';
      for (final key in keys) {
        if (data.containsKey(key) && data[key] != null) {
          final val = data[key];
          return '$val $unit';
        }
      }
      return 'Chưa có dữ liệu';
    }

    final sugarText = formatMetric(['sugars', 'sugars_100g'], 'g');
    final saltText = formatMetric(['salt', 'salt_100g'], 'g');

    final String warningText;
    if (allergenViolations.isNotEmpty) {
      warningText = 'Phát hiện chất gây dị ứng: ${allergenViolations.join(', ')}';
    } else if (ingredientsText != null && ingredientsText!.trim().isNotEmpty) {
      warningText = 'Chưa phát hiện chất dị ứng theo hồ sơ';
    } else {
      warningText = 'Chưa có dữ liệu';
    }

    final String evalReason;
    if (allergenViolations.isNotEmpty) {
      evalReason = 'Chứa thành phần dị ứng: ${allergenViolations.join(', ')}';
    } else if (nutritionViolations.isNotEmpty) {
      evalReason = nutritionViolations.join('; ');
    } else if (isIncomplete) {
      evalReason = 'Sản phẩm chưa đủ dữ liệu chi tiết';
    } else {
      evalReason = 'Đã lưu trong bộ nhớ máy';
    }

    return Food(
      id: barcode ?? (id != null ? id.toString() : 'unknown'),
      brand: brand ?? 'Chưa rõ thương hiệu',
      name: productName,
      weight: servingSize ?? '100 g',
      barcode: barcode ?? '',
      tone: tone,
      result: res,
      sugar: sugarText,
      salt: saltText,
      nova: 'Chưa có dữ liệu',
      nutriScore: nutriscoreGrade != null ? nutriscoreGrade!.toUpperCase() : 'Chưa có',
      ecoScore: 'Chưa có dữ liệu',
      reason: evalReason,
      ingredients: ingredientsText ?? 'Chưa có thông tin thành phần',
      allergenWarning: warningText,
      scanDate: cachedAt,
      summaryTags: nutriscoreGrade != null
          ? 'Nutri-Score ${nutriscoreGrade!.toUpperCase()}'
          : 'Đã lưu',
    );
  }
}
