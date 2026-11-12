import 'dart:convert';

class ProductNutrition {
  final int? id;
  final int productId;
  final Map<String, dynamic> nutritionData;

  ProductNutrition({
    this.id,
    required this.productId,
    required this.nutritionData,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'nutrition_data': jsonEncode(nutritionData),
    };
  }

  factory ProductNutrition.fromMap(Map<String, dynamic> map) {
    return ProductNutrition(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      nutritionData: map['nutrition_data'] != null
          ? jsonDecode(map['nutrition_data'] as String) as Map<String, dynamic>
          : {},
    );
  }
}
