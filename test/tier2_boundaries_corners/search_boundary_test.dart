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

  group('Tier 2: Search Boundary & Corner Cases', () {
    test('T2_SEARCH_01: Search query is case-insensitive and handles Vietnamese accents gracefully', () async {
      // Lowercase ASCII brand / keyword
      final lowerResults = await productRepository.searchProducts('cacao');
      expect(lowerResults, isNotEmpty);
      expect(lowerResults.first.productName, 'Bánh yến mạch cacao');

      // UPPERCASE ASCII keyword
      final upperResults = await productRepository.searchProducts('CACAO');
      expect(upperResults, isNotEmpty);
      expect(upperResults.first.productName, 'Bánh yến mạch cacao');

      // Vietnamese accented query with exact accent preservation
      final accentResults = await productRepository.searchProducts('Bánh yến mạch');
      expect(accentResults.length, greaterThanOrEqualTo(2));
    });

    test('T2_SEARCH_02: SQL wildcard characters and injection strings do not break query or leak data', () async {
      // SQL Injection: ' OR '1'='1
      const sqlInjection = "' OR '1'='1' --";
      final injectResults = await productRepository.searchProducts(sqlInjection);
      // Parameterized query ensures this searches literally for the string, returning 0 rows
      expect(injectResults, isEmpty);

      // Single quotes
      final quoteResults = await productRepository.searchProducts("'''");
      expect(quoteResults, isEmpty);

      // Semicolons and DROP TABLE attempts
      const dropAttempt = "Bánh'; DROP TABLE cached_product; --";
      final dropResults = await productRepository.searchProducts(dropAttempt);
      expect(dropResults, isEmpty);

      // Verify table still exists and is intact
      final allProducts = await productDao.getAllProducts();
      expect(allProducts.length, greaterThanOrEqualTo(2));
    });

    test('T2_SEARCH_03: Extremely long search query (250+ chars) handles gracefully without exception', () async {
      final longQuery = 'bánh_yến_mạch_' * 30; // 450 characters
      expect(longQuery.length, greaterThan(250));

      final results = await productRepository.searchProducts(longQuery);
      expect(results, isEmpty);
      expect(results, isA<List>());
    });

    test('T2_SEARCH_04: Query with leading/trailing whitespace trims properly and finds matches', () async {
      const whitespaceQuery = '    cacao    ';
      final results = await productRepository.searchProducts(whitespaceQuery);

      expect(results, isNotEmpty);
      expect(results.first.productName, 'Bánh yến mạch cacao');
      expect(results.first.brand, 'Mộc Hạt');
    });

    test('T2_SEARCH_05: Searching against an empty database returns empty list without throwing null-pointer', () async {
      // Clear database products
      await db.delete('cached_product');

      final results = await productRepository.searchProducts('bất kỳ sản phẩm nào');
      expect(results, isEmpty);

      // Empty query against empty db
      final emptyQueryResults = await productRepository.searchProducts('');
      expect(emptyQueryResults, isEmpty);
    });
  });
}
