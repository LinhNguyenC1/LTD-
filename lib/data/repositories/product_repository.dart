import 'dart:async';
import 'dart:io';

import '../local/daos/product_dao.dart';
import '../local/daos/nutrition_dao.dart';
import '../models/cached_product.dart';
import '../models/product_nutrition.dart';
import '../remote/open_food_facts_api.dart';

class ProductRepository {
  final ProductDao _productDao;
  final NutritionDao _nutritionDao;
  final OpenFoodFactsApi? _offClient;

  final Map<String, Future<CachedProduct?>> _inFlightRequests = {};
  bool simulateInsertFailure = false;

  ProductRepository({
    ProductDao? productDao,
    NutritionDao? nutritionDao,
    OpenFoodFactsApi? offClient,
  })  : _productDao = productDao ?? ProductDao(),
        _nutritionDao = nutritionDao ?? NutritionDao(),
        _offClient = offClient ?? OpenFoodFactsApi();

  Future<CachedProduct?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    // 1. Check local cache
    final map = await _productDao.getProductByBarcode(cleanBarcode);
    if (map != null) {
      return CachedProduct.fromMap(map);
    }

    // 2. Debounce in-flight network requests
    if (_offClient != null) {
      if (_inFlightRequests.containsKey(cleanBarcode)) {
        return await _inFlightRequests[cleanBarcode]!;
      }

      final future = _fetchAndCache(cleanBarcode);
      _inFlightRequests[cleanBarcode] = future;

      try {
        return await future;
      } finally {
        _inFlightRequests.remove(cleanBarcode);
      }
    }

    return null;
  }

  Future<CachedProduct?> _fetchAndCache(String barcode) async {
    try {
      final response = await _offClient!.fetchProduct(barcode);
      if (response.isNetworkError) {
        final msg =
            response.errorMessage ?? 'Lỗi kết nối mạng khi tra cứu sản phẩm';
        if (msg.toLowerCase().contains('timeout')) {
          throw TimeoutException(msg);
        }
        throw SocketException(msg);
      }
      if (!response.isSuccess || response.product == null) {
        return null;
      }

      final fetchedProduct = response.product!;
      final fetchedNutrition = response.nutrition;

      // 3. Cache aside to SQLite
      try {
        if (simulateInsertFailure) {
          throw Exception('Simulated SQLite disk write / lock failure');
        }

        final insertedId =
            await _productDao.insertProduct(fetchedProduct.toMap());
        if (fetchedNutrition != null) {
          final nutritionToSave = ProductNutrition(
            productId: insertedId,
            nutritionData: fetchedNutrition.nutritionData,
          );
          await _nutritionDao.insertOrUpdateNutrition(nutritionToSave.toMap());
        }

        return fetchedProduct.copyWith(id: insertedId);
      } catch (_) {
        // Even if cache insert fails, caller receives the valid fetched product
        return fetchedProduct;
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<CachedProduct> fetchAndCacheFromApi(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      throw ArgumentError('Mã vạch không được để trống');
    }

    final cached = await getProductByBarcode(cleanBarcode);
    if (cached != null) {
      return cached;
    }

    if (_offClient == null) {
      throw Exception('Không tìm thấy sản phẩm trong bộ nhớ cục bộ và API client chưa được cấu hình');
    }

    final response = await _offClient.fetchProduct(cleanBarcode);
    if (response.isNotFound) {
      throw Exception('Không tìm thấy sản phẩm với mã vạch $cleanBarcode');
    }
    if (response.isNetworkError) {
      final msg =
          response.errorMessage ?? 'Lỗi kết nối mạng khi tra cứu sản phẩm';
      if (msg.toLowerCase().contains('timeout')) {
        throw TimeoutException(msg);
      }
      throw SocketException(msg);
    }
    if (!response.isSuccess || response.product == null) {
      throw Exception(response.errorMessage ?? 'Lỗi khi tra cứu sản phẩm từ máy chủ');
    }

    final product = response.product!;
    try {
      if (simulateInsertFailure) {
        throw Exception('Simulated SQLite disk write / lock failure');
      }
      return await saveProductWithNutrition(
        product: product,
        nutritionData: response.nutrition?.nutritionData,
      );
    } catch (_) {
      return product;
    }
  }

  Future<List<CachedProduct>> searchProducts(String query) async {
    final maps = await _productDao.searchProducts(query);
    return maps.map((m) => CachedProduct.fromMap(m)).toList();
  }

  Future<ProductNutrition?> getNutritionByProductId(int productId) async {
    final map = await _nutritionDao.getNutritionByProductId(productId);
    if (map == null) return null;
    return ProductNutrition.fromMap(map);
  }

  Future<int> saveProduct(CachedProduct product) async {
    return await _productDao.insertProduct(product.toMap());
  }

  Future<int> saveNutrition(ProductNutrition nutrition) async {
    return await _nutritionDao.insertOrUpdateNutrition(nutrition.toMap());
  }

  Future<CachedProduct> saveProductWithNutrition({
    required CachedProduct product,
    Map<String, dynamic>? nutritionData,
  }) async {
    final productId = await _productDao.insertProduct(product.toMap());
    final savedProduct = product.copyWith(id: productId);

    if (nutritionData != null && nutritionData.isNotEmpty) {
      final nutrition = ProductNutrition(
        productId: productId,
        nutritionData: nutritionData,
      );
      await _nutritionDao.insertOrUpdateNutrition(nutrition.toMap());
    }

    return savedProduct;
  }
}
