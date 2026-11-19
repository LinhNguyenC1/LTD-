import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/product_nutrition.dart';
import 'package:an_lanh/data/local/db_helper.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  late ProductRepository productRepository;
  late ProductDao productDao;
  late NutritionDao nutritionDao;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    await createInMemoryTestDatabase(seedData: true);
    productDao = ProductDao();
    nutritionDao = NutritionDao();
    productRepository = ProductRepository(
      productDao: productDao,
      nutritionDao: nutritionDao,
    );
  });

  tearDown(() async {
    await DatabaseHelper.reset();
  });

  group('ProductRepository Tests', () {
    test('getProductByBarcode returns CachedProduct for seeded product', () async {
      final product =
          await productRepository.getProductByBarcode('8934567890123');
      expect(product, isNotNull);
      expect(product!.productName, 'Bánh yến mạch cacao');
      expect(product.brand, 'Mộc Hạt');
      expect(product.nutriscoreGrade, 'c');
      expect(product.barcode, '8934567890123');
    });

    test('getProductByBarcode returns null for non-existent barcode', () async {
      final product =
          await productRepository.getProductByBarcode('0000000000000');
      expect(product, isNull);
    });

    test('fetchAndCacheFromApi returns CachedProduct on cache hit', () async {
      final product =
          await productRepository.fetchAndCacheFromApi('8934567890456');
      expect(product.productName, 'Bánh yến mạch nguyên bản');
      expect(product.brand, 'An Mộc');
    });

    test('fetchAndCacheFromApi throws Exception on cache miss', () async {
      expect(
        () async => await productRepository.fetchAndCacheFromApi('9999999999999'),
        throwsA(isA<Exception>()),
      );
    });

    test('searchProducts returns mapped list of CachedProduct', () async {
      final results = await productRepository.searchProducts('nguyên bản');
      expect(results.length, 1);
      expect(results.first.productName, 'Bánh yến mạch nguyên bản');
      expect(results.first.brand, 'An Mộc');
    });

    test('getNutritionByProductId returns mapped ProductNutrition model', () async {
      final product =
          await productRepository.getProductByBarcode('8934567890123');
      expect(product, isNotNull);

      final nutrition =
          await productRepository.getNutritionByProductId(product!.id!);
      expect(nutrition, isNotNull);
      expect(nutrition!.productId, product.id);
      expect(nutrition.nutritionData['sugars'], 18.0);
      expect(nutrition.nutritionData['energy_kcal'], 450);
    });

    test('getNutritionByProductId returns null for invalid productId', () async {
      final nutrition = await productRepository.getNutritionByProductId(88888);
      expect(nutrition, isNull);
    });

    test('saveProduct inserts new product and returns id', () async {
      final now = DateTime.now().toIso8601String();
      final newProduct = CachedProduct(
        barcode: '8937777777777',
        productName: 'Trà ô long không đường',
        brand: 'Tea+',
        cachedAt: now,
      );

      final id = await productRepository.saveProduct(newProduct);
      expect(id, greaterThan(0));

      final retrieved =
          await productRepository.getProductByBarcode('8937777777777');
      expect(retrieved, isNotNull);
      expect(retrieved!.productName, 'Trà ô long không đường');
    });

    test('saveNutrition inserts and updates nutrition data', () async {
      final product =
          await productRepository.getProductByBarcode('8934567890456');
      expect(product, isNotNull);

      final updatedNut = ProductNutrition(
        productId: product!.id!,
        nutritionData: {'energy_kcal': 400, 'sugars': 5.0},
      );

      final nutId = await productRepository.saveNutrition(updatedNut);
      expect(nutId, greaterThan(0));

      final fetched =
          await productRepository.getNutritionByProductId(product.id!);
      expect(fetched, isNotNull);
      expect(fetched!.nutritionData['energy_kcal'], 400);
      expect(fetched.nutritionData['sugars'], 5.0);
    });

    test('saveProductWithNutrition saves product and linked nutrition atomics',
        () async {
      final now = DateTime.now().toIso8601String();
      final product = CachedProduct(
        barcode: '8938888888888',
        productName: 'Ngũ cốc ăn sáng Granola',
        brand: 'Healthy Food',
        cachedAt: now,
      );

      final saved = await productRepository.saveProductWithNutrition(
        product: product,
        nutritionData: {
          'energy_kcal': 420,
          'protein': 12.0,
          'sugars': 6.5,
        },
      );

      expect(saved.id, greaterThan(0));

      final fetchedProduct =
          await productRepository.getProductByBarcode('8938888888888');
      expect(fetchedProduct, isNotNull);
      expect(fetchedProduct!.id, saved.id);

      final fetchedNut =
          await productRepository.getNutritionByProductId(saved.id!);
      expect(fetchedNut, isNotNull);
      expect(fetchedNut!.nutritionData['protein'], 12.0);
      expect(fetchedNut.nutritionData['sugars'], 6.5);
    });
  });
}
