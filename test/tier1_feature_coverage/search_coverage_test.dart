import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import '../helpers/test_database_helper.dart';

void main() {
  late Database db;
  late ProductDao productDao;
  late ProductRepository productRepository;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: true);
    productDao = ProductDao();
    productRepository = ProductRepository(productDao: productDao);
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  group('Tier 1: Search Coverage Tests', () {
    test('T1_SEARCH_01: Querying exact product name returns corresponding CachedProduct', () async {
      final results = await productRepository.searchProducts('Bánh yến mạch cacao');

      expect(results, isNotEmpty);
      expect(results.first.productName, 'Bánh yến mạch cacao');
      expect(results.first.barcode, '8934567890123');
      expect(results.first.brand, 'Mộc Hạt');
    });

    test('T1_SEARCH_02: Querying partial name ("yến mạch") returns multiple matching products', () async {
      final results = await productRepository.searchProducts('yến mạch');

      expect(results.length, greaterThanOrEqualTo(2));
      final names = results.map((p) => p.productName).toList();
      expect(names, containsAll(['Bánh yến mạch cacao', 'Bánh yến mạch nguyên bản']));
    });

    test('T1_SEARCH_03: Querying exact numeric barcode returns matched product record', () async {
      final results = await productRepository.searchProducts('8934567890456');

      expect(results.length, 1);
      expect(results.first.barcode, '8934567890456');
      expect(results.first.productName, 'Bánh yến mạch nguyên bản');
      expect(results.first.brand, 'An Mộc');
    });

    test('T1_SEARCH_04: Querying brand name correctly filters products', () async {
      final mocHatResults = await productRepository.searchProducts('Mộc Hạt');
      expect(mocHatResults, isNotEmpty);
      expect(mocHatResults.every((p) => p.brand == 'Mộc Hạt'), isTrue);

      final anMocResults = await productRepository.searchProducts('An Mộc');
      expect(anMocResults, isNotEmpty);
      expect(anMocResults.every((p) => p.brand == 'An Mộc'), isTrue);
    });

    test('T1_SEARCH_05: Querying non-existent keyword returns empty list without error', () async {
      final results = await productRepository.searchProducts('Bánh pizza thập cẩm 99999');

      expect(results, isEmpty);
      expect(results, isA<List>());
    });
  });
}
