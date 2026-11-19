import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:an_lanh/business_logic/viewmodels/search_viewmodel.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import 'package:an_lanh/presentation/screens/home/search_page.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;
  late SearchViewModel searchViewModel;

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
  ];

  setUp(() {
    mockRepo = MockProductRepository();
    when(() => mockRepo.searchProducts(any())).thenAnswer((_) async => []);
    searchViewModel = SearchViewModel(productRepository: mockRepo);
  });

  tearDown(() {
    searchViewModel.dispose();
  });

  Widget buildTestWidget() {
    return ChangeNotifierProvider<SearchViewModel>.value(
      value: searchViewModel,
      child: const MaterialApp(
        home: SearchPage(),
      ),
    );
  }

  testWidgets('renders search page with input and all 4 filter chips', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_input_field')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_all')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_name')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_barcode')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_brand')), findsOneWidget);
  });

  testWidgets('shows empty state when no products found', (tester) async {
    when(() => mockRepo.searchProducts(any())).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy sản phẩm phù hợp'), findsOneWidget);
    expect(find.text('Thử kiểm tra lại tên, mã vạch hoặc đổi bộ lọc'), findsOneWidget);
    expect(find.byKey(const Key('search_reset_button')), findsOneWidget);
  });

  testWidgets('renders list of products when search returns items', (tester) async {
    when(() => mockRepo.searchProducts(''))
        .thenAnswer((_) async => sampleProducts);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Bánh yến mạch cacao'), findsOneWidget);
    expect(find.text('Bánh yến mạch nguyên bản'), findsOneWidget);
    expect(find.text('2 sản phẩm tìm thấy'), findsOneWidget);
  });

  testWidgets('filter chips update selected filter', (tester) async {
    when(() => mockRepo.searchProducts(''))
        .thenAnswer((_) async => sampleProducts);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter_chip_name')));
    await tester.pumpAndSettle();
    expect(searchViewModel.selectedFilter, equals('name'));

    await tester.tap(find.byKey(const Key('filter_chip_barcode')));
    await tester.pumpAndSettle();
    expect(searchViewModel.selectedFilter, equals('barcode'));

    await tester.tap(find.byKey(const Key('filter_chip_brand')));
    await tester.pumpAndSettle();
    expect(searchViewModel.selectedFilter, equals('brand'));
  });

  testWidgets('typing text in search bar updates query and shows clear button', (tester) async {
    when(() => mockRepo.searchProducts(any())).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('search_input_field')),
      'cacao',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_clear_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('search_clear_button')));
    await tester.pumpAndSettle();

    expect(searchViewModel.searchQuery, isEmpty);
  });

  testWidgets('tapping reset button in empty state clears input', (tester) async {
    when(() => mockRepo.searchProducts(any())).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('search_input_field')),
      'non-existent',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_reset_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('search_reset_button')));
    await tester.pumpAndSettle();

    expect(searchViewModel.searchQuery, isEmpty);
    expect(searchViewModel.selectedFilter, equals('all'));
  });
}
