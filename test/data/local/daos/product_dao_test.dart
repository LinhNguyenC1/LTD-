import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/local/db_helper.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late ProductDao productDao;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    await createInMemoryTestDatabase(seedData: false);
    productDao = ProductDao();
  });

  tearDown(() async {
    await DatabaseHelper.reset();
  });

  group('ProductDao Tests', () {
    test('insertProduct with barcode inserts new product', () async {
      final now = DateTime.now().toIso8601String();
      final id = await productDao.insertProduct({
        'barcode': '1234567890123',
        'product_name': 'Sữa tươi tiệt trùng',
        'brand': 'Vinamilk',
        'nutriscore_grade': 'a',
        'cached_at': now,
      });

      expect(id, greaterThan(0));

      final fetched = await productDao.getProductById(id);
      expect(fetched, isNotNull);
      expect(fetched!['barcode'], '1234567890123');
      expect(fetched['product_name'], 'Sữa tươi tiệt trùng');
      expect(fetched['brand'], 'Vinamilk');
    });

    test('insertProduct with existing barcode updates existing record', () async {
      final now = DateTime.now().toIso8601String();
      final id1 = await productDao.insertProduct({
        'barcode': '8930000000001',
        'product_name': 'Trà xanh không đường',
        'brand': 'C2',
        'cached_at': now,
      });

      final id2 = await productDao.insertProduct({
        'barcode': '8930000000001',
        'product_name': 'Trà xanh ít đường',
        'brand': 'C2',
        'cached_at': now,
      });

      expect(id2, equals(id1));

      final fetched = await productDao.getProductByBarcode('8930000000001');
      expect(fetched, isNotNull);
      expect(fetched!['product_name'], 'Trà xanh ít đường');
    });

    test('insertProduct without barcode succeeds for OCR/manual input', () async {
      final now = DateTime.now().toIso8601String();
      final id = await productDao.insertProduct({
        'barcode': null,
        'product_name': 'Bánh mì ngũ cốc',
        'brand': 'Tiệm Bánh',
        'cached_at': now,
      });

      expect(id, greaterThan(0));
      final fetched = await productDao.getProductById(id);
      expect(fetched, isNotNull);
      expect(fetched!['barcode'], isNull);
      expect(fetched['product_name'], 'Bánh mì ngũ cốc');
    });

    test('getProductByBarcode returns null for non-existent barcode', () async {
      final res = await productDao.getProductByBarcode('0000000000000');
      expect(res, isNull);
    });

    test('searchProducts finds products by name, brand, or barcode', () async {
      final now = DateTime.now().toIso8601String();
      await productDao.insertProduct({
        'barcode': '8931111111111',
        'product_name': 'Bánh quy bơ Danisa',
        'brand': 'Danisa',
        'cached_at': now,
      });
      await productDao.insertProduct({
        'barcode': '8932222222222',
        'product_name': 'Kẹo dẻo hương dâu',
        'brand': 'Chupa Chups',
        'cached_at': now,
      });
      await productDao.insertProduct({
        'barcode': '8933333333333',
        'product_name': 'Sữa hạt óc chó',
        'brand': 'TH True Nut',
        'cached_at': now,
      });

      // Search by name
      final byName = await productDao.searchProducts('quy bơ');
      expect(byName.length, 1);
      expect(byName.first['product_name'], 'Bánh quy bơ Danisa');

      // Search by brand
      final byBrand = await productDao.searchProducts('TH True');
      expect(byBrand.length, 1);
      expect(byBrand.first['product_name'], 'Sữa hạt óc chó');

      // Search by barcode substring
      final byBarcode = await productDao.searchProducts('222222');
      expect(byBarcode.length, 1);
      expect(byBarcode.first['product_name'], 'Kẹo dẻo hương dâu');

      // Case-insensitive search
      final byCase = await productDao.searchProducts('DANISA');
      expect(byCase.length, 1);
      expect(byCase.first['brand'], 'Danisa');

      // Empty query returns all
      final all = await productDao.searchProducts('');
      expect(all.length, 3);

      // No match
      final noMatch = await productDao.searchProducts('Không tồn tại');
      expect(noMatch, isEmpty);
    });

    test('deleteProduct deletes record by id', () async {
      final now = DateTime.now().toIso8601String();
      final id = await productDao.insertProduct({
        'barcode': '8939999999999',
        'product_name': 'Sản phẩm thử nghiệm',
        'cached_at': now,
      });

      final count = await productDao.deleteProduct(id);
      expect(count, 1);

      final fetched = await productDao.getProductById(id);
      expect(fetched, isNull);
    });
  });
}
