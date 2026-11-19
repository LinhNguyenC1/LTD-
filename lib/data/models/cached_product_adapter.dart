import 'cached_product.dart';
import 'food.dart';

extension CachedProductAdapter on CachedProduct {
  Food toFood() {
    final grade = nutriscoreGrade?.toLowerCase();
    final String tone;
    final Result res;

    if (isIncomplete) {
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

    return Food(
      id: barcode ?? (id != null ? id.toString() : 'unknown'),
      brand: brand ?? 'Chưa rõ thương hiệu',
      name: productName,
      weight: servingSize ?? '100 g',
      barcode: barcode ?? '',
      tone: tone,
      result: res,
      sugar: '',
      salt: '',
      nova: '',
      nutriScore: nutriscoreGrade != null ? nutriscoreGrade!.toUpperCase() : 'Chưa có',
      ecoScore: '',
      reason: isIncomplete
          ? 'Sản phẩm chưa đủ dữ liệu chi tiết'
          : 'Đã lưu trong bộ nhớ máy',
      ingredients: ingredientsText ?? 'Chưa có thông tin thành phần',
      allergenWarning: '',
      scanDate: cachedAt,
      summaryTags: nutriscoreGrade != null
          ? 'Nutri-Score ${nutriscoreGrade!.toUpperCase()}'
          : 'Đã lưu',
    );
  }
}
