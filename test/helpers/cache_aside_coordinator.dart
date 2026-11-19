import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/product_nutrition.dart';
import 'open_food_facts_client.dart';

class CacheAsideCoordinator {
  final ProductDao _productDao;
  final NutritionDao _nutritionDao;
  final OpenFoodFactsClient _offClient;

  // Track debounced network requests
  final Map<String, Future<CachedProduct?>> _inFlightRequests = {};
  int networkCallCount = 0;
  bool simulateInsertFailure = false;

  CacheAsideCoordinator({
    required ProductDao productDao,
    required NutritionDao nutritionDao,
    required OpenFoodFactsClient offClient,
  })  : _productDao = productDao,
        _nutritionDao = nutritionDao,
        _offClient = offClient;

  Future<CachedProduct?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    // 1. Check local cache
    final localMap = await _productDao.getProductByBarcode(cleanBarcode);
    if (localMap != null) {
      return CachedProduct.fromMap(localMap);
    }

    // 2. Debounce in-flight network requests
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

  Future<CachedProduct?> _fetchAndCache(String barcode) async {
    networkCallCount++;
    final apiResponse = await _offClient.fetchProduct(barcode);

    if (!apiResponse.isSuccess || apiResponse.product == null) {
      return null;
    }

    final fetchedProduct = apiResponse.product!;
    final fetchedNutrition = apiResponse.nutrition;

    // 3. Cache aside to SQLite
    try {
      if (simulateInsertFailure) {
        throw Exception('Simulated SQLite disk write / lock failure');
      }

      final insertedId = await _productDao.insertProduct(fetchedProduct.toMap());
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
  }
}
