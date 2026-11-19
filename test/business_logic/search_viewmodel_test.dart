import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:an_lanh/business_logic/viewmodels/search_viewmodel.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;
  late SearchViewModel viewModel;

  final sampleProducts = [
    CachedProduct(
      id: 1,
      barcode: '8930000000128',
      productName: 'Bánh yến mạch cacao',
      brand: 'Mộc Hạt',
      nutriscoreGrade: 'c',
      cachedAt: '2026-01-01',
    ),
    CachedProduct(
      id: 2,
      barcode: '8930000000129',
      productName: 'Bánh yến mạch nguyên bản',
      brand: 'An Mộc',
      nutriscoreGrade: 'b',
      cachedAt: '2026-01-01',
    ),
    CachedProduct(
      id: 3,
      barcode: '8930000000789',
      productName: 'Bánh gạo mè',
      brand: 'Lúa Nhỏ',
      nutriscoreGrade: 'b',
      cachedAt: '2026-01-01',
    ),
  ];

  setUp(() {
    mockRepo = MockProductRepository();
    viewModel = SearchViewModel(productRepository: mockRepo);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('SearchViewModel - Initial State', () {
    test('initial values are correct', () {
      expect(viewModel.searchResults, isEmpty);
      expect(viewModel.isSearching, isFalse);
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.selectedFilter, equals('all'));
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.totalCount, equals(0));
    });
  });

  group('SearchViewModel - search', () {
    test('populates searchResults on success', () async {
      when(() => mockRepo.searchProducts('yến mạch'))
          .thenAnswer((_) async => [sampleProducts[0], sampleProducts[1]]);

      await viewModel.search('yến mạch');

      expect(viewModel.isSearching, isFalse);
      expect(viewModel.searchResults.length, equals(2));
      expect(viewModel.totalCount, equals(2));
      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.searchQuery, equals('yến mạch'));
      expect(viewModel.errorMessage, isNull);
    });

    test('handles empty search query returning all items', () async {
      when(() => mockRepo.searchProducts(''))
          .thenAnswer((_) async => sampleProducts);

      await viewModel.search('');

      expect(viewModel.searchResults.length, equals(3));
      expect(viewModel.totalCount, equals(3));
      expect(viewModel.isEmpty, isFalse);
    });

    test('handles empty results from repository', () async {
      when(() => mockRepo.searchProducts('unknown'))
          .thenAnswer((_) async => []);

      await viewModel.search('unknown');

      expect(viewModel.searchResults, isEmpty);
      expect(viewModel.totalCount, equals(0));
      expect(viewModel.isEmpty, isTrue);
    });

    test('handles repository error gracefully', () async {
      when(() => mockRepo.searchProducts(any()))
          .thenThrow(Exception('Database disk full'));

      await viewModel.search('error');

      expect(viewModel.isSearching, isFalse);
      expect(viewModel.searchResults, isEmpty);
      expect(viewModel.errorMessage, contains('Lỗi tìm kiếm'));
      expect(viewModel.isEmpty, isTrue);
    });
  });

  group('SearchViewModel - filterBy', () {
    test('filters by name correctly', () async {
      when(() => mockRepo.searchProducts('cacao'))
          .thenAnswer((_) async => [sampleProducts[0]]);

      await viewModel.search('cacao');
      viewModel.filterBy('name');

      expect(viewModel.selectedFilter, equals('name'));
      expect(viewModel.searchResults.length, equals(1));
      expect(viewModel.searchResults.first.productName, contains('cacao'));
    });

    test('filters by barcode correctly', () async {
      when(() => mockRepo.searchProducts('8930000000128'))
          .thenAnswer((_) async => [sampleProducts[0]]);

      await viewModel.search('8930000000128');
      viewModel.filterBy('barcode');

      expect(viewModel.selectedFilter, equals('barcode'));
      expect(viewModel.searchResults.length, equals(1));
      expect(viewModel.searchResults.first.barcode, equals('8930000000128'));
    });

    test('filters by brand correctly', () async {
      when(() => mockRepo.searchProducts('An Mộc'))
          .thenAnswer((_) async => [sampleProducts[1]]);

      await viewModel.search('An Mộc');
      viewModel.filterBy('brand');

      expect(viewModel.selectedFilter, equals('brand'));
      expect(viewModel.searchResults.length, equals(1));
      expect(viewModel.searchResults.first.brand, equals('An Mộc'));
    });

    test('switching back to all restores full match set', () async {
      when(() => mockRepo.searchProducts(''))
          .thenAnswer((_) async => sampleProducts);

      await viewModel.search('');
      viewModel.filterBy('brand');
      viewModel.filterBy('all');

      expect(viewModel.selectedFilter, equals('all'));
      expect(viewModel.searchResults.length, equals(3));
    });
  });

  group('SearchViewModel - clearSearch', () {
    test('resets query and triggers search with empty string', () async {
      when(() => mockRepo.searchProducts(''))
          .thenAnswer((_) async => sampleProducts);

      viewModel.clearSearch();

      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.errorMessage, isNull);
    });
  });

  group('SearchViewModel - searchDebounced', () {
    test('triggers search after specified duration', () async {
      when(() => mockRepo.searchProducts('gạo'))
          .thenAnswer((_) async => [sampleProducts[2]]);

      viewModel.searchDebounced(
        'gạo',
        duration: const Duration(milliseconds: 50),
      );

      expect(viewModel.searchQuery, equals('gạo'));
      await Future.delayed(const Duration(milliseconds: 80));

      expect(viewModel.searchResults.length, equals(1));
      expect(viewModel.searchResults.first.productName, equals('Bánh gạo mè'));
    });
  });

  group('SearchViewModel - out-of-order concurrency', () {
    test('stale response from earlier query does not overwrite newer query',
        () async {
      final completerA = Completer<List<CachedProduct>>();
      final completerB = Completer<List<CachedProduct>>();

      when(() => mockRepo.searchProducts('queryA'))
          .thenAnswer((_) => completerA.future);
      when(() => mockRepo.searchProducts('queryB'))
          .thenAnswer((_) => completerB.future);

      final productA = CachedProduct(
        id: 10,
        barcode: '8930000000010',
        productName: 'Sản phẩm queryA',
        brand: 'Brand A',
        cachedAt: '2026-01-01',
      );
      final productB = CachedProduct(
        id: 20,
        barcode: '8930000000020',
        productName: 'Sản phẩm queryB',
        brand: 'Brand B',
        cachedAt: '2026-01-01',
      );

      final futureA = viewModel.search('queryA');
      expect(viewModel.isSearching, isTrue);
      expect(viewModel.searchQuery, equals('queryA'));

      final futureB = viewModel.search('queryB');
      expect(viewModel.isSearching, isTrue);
      expect(viewModel.searchQuery, equals('queryB'));

      completerB.complete([productB]);
      await futureB;

      expect(viewModel.isSearching, isFalse);
      expect(viewModel.searchResults.length, equals(1));
      expect(
          viewModel.searchResults.first.productName, equals('Sản phẩm queryB'));

      completerA.complete([productA]);
      await futureA;

      expect(viewModel.isSearching, isFalse);
      expect(viewModel.searchQuery, equals('queryB'));
      expect(viewModel.searchResults.length, equals(1));
      expect(
          viewModel.searchResults.first.productName, equals('Sản phẩm queryB'));
    });

    test('stale error from earlier query does not clear newer query results',
        () async {
      final completerA = Completer<List<CachedProduct>>();
      final completerB = Completer<List<CachedProduct>>();

      when(() => mockRepo.searchProducts('queryA'))
          .thenAnswer((_) => completerA.future);
      when(() => mockRepo.searchProducts('queryB'))
          .thenAnswer((_) => completerB.future);

      final productB = CachedProduct(
        id: 20,
        barcode: '8930000000020',
        productName: 'Sản phẩm queryB',
        brand: 'Brand B',
        cachedAt: '2026-01-01',
      );

      final futureA = viewModel.search('queryA');
      final futureB = viewModel.search('queryB');

      completerB.complete([productB]);
      await futureB;

      expect(viewModel.searchResults.length, equals(1));
      expect(viewModel.errorMessage, isNull);

      completerA.completeError(Exception('Network timeout on queryA'));
      await futureA;

      expect(viewModel.errorMessage, isNull);
      expect(viewModel.searchResults.length, equals(1));
      expect(
          viewModel.searchResults.first.productName, equals('Sản phẩm queryB'));
    });
  });
}
