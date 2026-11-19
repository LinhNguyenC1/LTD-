import 'dart:convert';

class CachedProduct {
  final int? id;
  final String? barcode;
  final String productName;
  final String? brand;
  final String? imageUrl;
  final String? ingredientsText;
  final String? servingSize;
  final String? nutriscoreGrade;
  final bool isIncomplete;
  final List<String> missingFields;
  final String cachedAt;

  CachedProduct({
    this.id,
    this.barcode,
    required this.productName,
    this.brand,
    this.imageUrl,
    this.ingredientsText,
    this.servingSize,
    this.nutriscoreGrade,
    this.isIncomplete = false,
    this.missingFields = const [],
    required this.cachedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barcode': barcode,
      'product_name': productName,
      'brand': brand,
      'image_url': imageUrl,
      'ingredients_text': ingredientsText,
      'serving_size': servingSize,
      'nutriscore_grade': nutriscoreGrade,
      'is_incomplete': isIncomplete ? 1 : 0,
      'missing_fields': jsonEncode(missingFields),
      'cached_at': cachedAt,
    };
  }

  factory CachedProduct.fromMap(Map<String, dynamic> map) {
    List<String> parsedMissing = [];
    if (map['missing_fields'] != null &&
        (map['missing_fields'] as String).isNotEmpty) {
      parsedMissing =
          List<String>.from(jsonDecode(map['missing_fields'] as String));
    }

    return CachedProduct(
      id: map['id'] as int?,
      barcode: map['barcode'] as String?,
      productName: map['product_name'] as String,
      brand: map['brand'] as String?,
      imageUrl: map['image_url'] as String?,
      ingredientsText: map['ingredients_text'] as String?,
      servingSize: map['serving_size'] as String?,
      nutriscoreGrade: map['nutriscore_grade'] as String?,
      isIncomplete: (map['is_incomplete'] as int? ?? 0) == 1,
      missingFields: parsedMissing,
      cachedAt: map['cached_at'] as String,
    );
  }

  CachedProduct copyWith({
    int? id,
    String? barcode,
    String? productName,
    String? brand,
    String? imageUrl,
    String? ingredientsText,
    String? servingSize,
    String? nutriscoreGrade,
    bool? isIncomplete,
    List<String>? missingFields,
    String? cachedAt,
  }) {
    return CachedProduct(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredientsText: ingredientsText ?? this.ingredientsText,
      servingSize: servingSize ?? this.servingSize,
      nutriscoreGrade: nutriscoreGrade ?? this.nutriscoreGrade,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      missingFields: missingFields ?? this.missingFields,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}
