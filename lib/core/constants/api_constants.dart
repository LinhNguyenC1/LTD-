class ApiConstants {
  static const String baseUrl = 'https://world.openfoodfacts.org';
  static const String productEndpoint = '/api/v2/product';
  static const String defaultFields =
      'product_name,brands,image_url,ingredients_text,serving_size,nutriscore_grade,nutriments,allergens_tags';
  static const String userAgentHeader =
      'AnLanhApp - Dart/Flutter - Version 1.0.0';
  static const String acceptHeader = 'application/json';
  static const Duration defaultTimeout = Duration(seconds: 10);
}
