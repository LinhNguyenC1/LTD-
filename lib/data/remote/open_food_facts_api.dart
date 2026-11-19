import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/cached_product.dart';
import '../models/product_nutrition.dart';

enum OffStatus { success, notFound, networkError, formatError }

class OffApiResponse {
  final OffStatus status;
  final CachedProduct? product;
  final ProductNutrition? nutrition;
  final String? errorMessage;

  OffApiResponse({
    required this.status,
    this.product,
    this.nutrition,
    this.errorMessage,
  });

  bool get isSuccess => status == OffStatus.success;
  bool get isNotFound => status == OffStatus.notFound;
  bool get isNetworkError => status == OffStatus.networkError;
  bool get isFormatError => status == OffStatus.formatError;

  factory OffApiResponse.success({
    required CachedProduct product,
    ProductNutrition? nutrition,
  }) {
    return OffApiResponse(
      status: OffStatus.success,
      product: product,
      nutrition: nutrition,
    );
  }

  factory OffApiResponse.notFound({String? message}) {
    return OffApiResponse(
      status: OffStatus.notFound,
      errorMessage: message ?? 'Sản phẩm không tìm thấy trên hệ thống.',
    );
  }

  factory OffApiResponse.networkError({String? message}) {
    return OffApiResponse(
      status: OffStatus.networkError,
      errorMessage: message ?? 'Lỗi kết nối mạng, vui lòng thử lại sau.',
    );
  }

  factory OffApiResponse.formatError({String? message}) {
    return OffApiResponse(
      status: OffStatus.formatError,
      errorMessage: message ?? 'Dữ liệu phản hồi từ máy chủ không hợp lệ.',
    );
  }
}

typedef ApiResponse<T> = OffApiResponse;
typedef OpenFoodFactsClient = OpenFoodFactsApi;

class OpenFoodFactsApi {
  final http.Client _client;
  final Duration timeout;

  OpenFoodFactsApi({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        timeout = timeout ?? ApiConstants.defaultTimeout;

  Future<OffApiResponse> fetchProduct(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return OffApiResponse.formatError(message: 'Mã vạch không được để trống.');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.productEndpoint}/$cleanBarcode.json?fields=${ApiConstants.defaultFields}',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': ApiConstants.userAgentHeader,
          'Accept': ApiConstants.acceptHeader,
        },
      ).timeout(timeout);

      if (response.statusCode == 404) {
        return OffApiResponse.notFound();
      }
      if (response.statusCode >= 500) {
        return OffApiResponse.networkError(
          message:
              'Máy chủ phản hồi lỗi (${response.statusCode}). Vui lòng thử lại sau.',
        );
      }
      if (response.statusCode >= 400 && response.statusCode != 404) {
        return OffApiResponse.formatError(
          message: 'Yêu cầu không hợp lệ (${response.statusCode}).',
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('json') && !response.body.trim().startsWith('{')) {
        return OffApiResponse.formatError(
          message: 'Phản hồi không phải định dạng JSON hợp lệ.',
        );
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        return OffApiResponse.formatError();
      }

      final statusNum = json['status'] as int? ?? 0;
      if (statusNum == 0 || json['product'] == null) {
        return OffApiResponse.notFound();
      }

      final productMap = json['product'] as Map<String, dynamic>;
      final now = DateTime.now().toIso8601String();

      final productName = productMap['product_name'] as String? ?? 'Sản phẩm không tên';
      final brand = productMap['brands'] as String?;
      final imageUrl = (productMap['image_url'] ?? productMap['image_front_url']) as String?;
      final ingredientsText = (productMap['ingredients_text'] ?? productMap['ingredients_text_vi']) as String?;
      final servingSize = productMap['serving_size'] as String?;
      final nutriscoreGrade = productMap['nutriscore_grade'] as String?;

      final List<String> missingFields = [];
      if (ingredientsText == null || ingredientsText.trim().isEmpty) {
        missingFields.add('ingredients_text');
      }

      final rawNutriments = productMap['nutriments'] as Map<String, dynamic>?;
      Map<String, dynamic>? nutriments;

      if (rawNutriments != null && rawNutriments.isNotEmpty) {
        nutriments = <String, dynamic>{};
        for (final entry in rawNutriments.entries) {
          final val = entry.value;
          if (val is num) {
            nutriments[entry.key] = val;
          } else if (val is String) {
            final parsed = num.tryParse(val.trim());
            nutriments[entry.key] = parsed ?? val;
          } else {
            nutriments[entry.key] = val;
          }
        }

        void syncNutrient(String shortKey, String fullKey) {
          if (nutriments!.containsKey(fullKey) && !nutriments.containsKey(shortKey)) {
            nutriments[shortKey] = nutriments[fullKey];
          } else if (nutriments.containsKey(shortKey) && !nutriments.containsKey(fullKey)) {
            nutriments[fullKey] = nutriments[shortKey];
          }
        }

        syncNutrient('energy_kcal', 'energy-kcal_100g');
        syncNutrient('sugars', 'sugars_100g');
        syncNutrient('fat', 'fat_100g');
        syncNutrient('saturated_fat', 'saturated-fat_100g');
        syncNutrient('protein', 'proteins_100g');
        syncNutrient('salt', 'salt_100g');
        syncNutrient('sodium', 'sodium_100g');
      }

      if (nutriments == null || nutriments.isEmpty) {
        missingFields.add('nutriments');
      }

      final isIncomplete = missingFields.isNotEmpty;

      final cachedProduct = CachedProduct(
        barcode: cleanBarcode,
        productName: productName,
        brand: brand,
        imageUrl: imageUrl,
        ingredientsText: ingredientsText,
        servingSize: servingSize,
        nutriscoreGrade: nutriscoreGrade,
        isIncomplete: isIncomplete,
        missingFields: missingFields,
        cachedAt: now,
      );

      ProductNutrition? nutrition;
      if (nutriments != null && nutriments.isNotEmpty) {
        nutrition = ProductNutrition(
          productId: 0,
          nutritionData: nutriments,
        );
      }

      return OffApiResponse.success(
        product: cachedProduct,
        nutrition: nutrition,
      );
    } on SocketException {
      return OffApiResponse.networkError();
    } on TimeoutException {
      return OffApiResponse.networkError(message: 'Hết thời gian chờ kết nối (Timeout).');
    } on http.ClientException {
      return OffApiResponse.networkError();
    } catch (e) {
      return OffApiResponse.formatError(message: 'Lỗi xử lý: $e');
    }
  }
}
