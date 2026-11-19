import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:an_lanh/business_logic/viewmodels/scan_viewmodel.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/food.dart';
import 'package:an_lanh/data/models/product_nutrition.dart';
import 'package:an_lanh/data/models/user_profile.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import 'package:an_lanh/data/repositories/profile_repository.dart';
import 'package:an_lanh/data/local/daos/history_dao.dart';
import 'package:an_lanh/presentation/screens/scan/scan_page.dart';
import 'package:an_lanh/presentation/screens/scan/lookup_not_found_page.dart';
import 'package:an_lanh/presentation/screens/scan/lookup_error_page.dart';
import 'package:an_lanh/core/services/notification_service.dart';

class MockProductRepoForScanPage extends ProductRepository {
  final Map<String, CachedProduct> products = {};
  bool simulateNetworkError = false;

  @override
  Future<CachedProduct?> getProductByBarcode(String barcode) async {
    if (simulateNetworkError) {
      throw Exception('Network connection failed');
    }
    return products[barcode];
  }

  @override
  Future<ProductNutrition?> getNutritionByProductId(int productId) async {
    return null;
  }
}

class MockHistoryDaoForScanPage extends HistoryDao {
  @override
  Future<int> insertHistoryItem(item) async => 1;
}

class MockProfileRepoForScanPage extends ProfileRepository {
  @override
  Future<UserProfile?> fetchUserProfile() async => null;
}

void main() {
  late MockProductRepoForScanPage mockRepo;
  late MockHistoryDaoForScanPage mockHistory;
  late MockProfileRepoForScanPage mockProfile;
  late NotificationService notifService;
  late ScanViewModel scanVm;
  Food? openedFood;

  setUp(() {
    mockRepo = MockProductRepoForScanPage();
    mockHistory = MockHistoryDaoForScanPage();
    mockProfile = MockProfileRepoForScanPage();
    notifService = NotificationService.forTest();
    scanVm = ScanViewModel(
      productRepository: mockRepo,
      profileRepository: mockProfile,
      historyDao: mockHistory,
      notificationService: notifService,
    );
    openedFood = null;

    mockRepo.products['8934567890456'] = CachedProduct(
      id: 1,
      barcode: '8934567890456',
      productName: 'Bánh nguyên bản test',
      cachedAt: DateTime.now().toIso8601String(),
    );
    mockRepo.products['8934567890123'] = CachedProduct(
      id: 2,
      barcode: '8934567890123',
      productName: 'Bánh cacao test',
      cachedAt: DateTime.now().toIso8601String(),
    );
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<ScanViewModel>.value(
        value: scanVm,
        child: ScanPage(
          onOpenFood: (food) => openedFood = food,
        ),
      ),
    );
  }

  group('ScanPage Widget Tests', () {
    testWidgets('renders initial camera scan view with tabs and controls', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Camera Quét Sản Phẩm'), findsOneWidget);
      expect(find.text('Mã vạch'), findsOneWidget);
      expect(find.text('Thành phần'), findsOneWidget);
      expect(find.text('Nhập số'), findsOneWidget);
      expect(find.text('Đưa mã vạch vào khung'), findsOneWidget);
      expect(find.text('Tra cứu mã vạch'), findsOneWidget);
    });

    testWidgets('switches to manual input mode when tapping Nhập số tab', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Nhập số'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tra cứu theo số mã vạch'), findsOneWidget);
      expect(find.byKey(const Key('scan_barcode_input_field')), findsOneWidget);
      expect(find.byKey(const Key('scan_manual_submit_button')), findsOneWidget);

      expect(find.byKey(const Key('chip_simulation_coca')), findsOneWidget);
      expect(find.byKey(const Key('chip_simulation_nutella')), findsOneWidget);
      expect(find.byKey(const Key('chip_simulation_cacao')), findsOneWidget);
      expect(find.byKey(const Key('chip_simulation_original')), findsOneWidget);
      expect(find.byKey(const Key('chip_simulation_404')), findsOneWidget);
    });

    testWidgets('displays validation error when submitting invalid barcode', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Nhập số'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('scan_barcode_input_field')), '12345');
      await tester.tap(find.byKey(const Key('scan_manual_submit_button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mã vạch không hợp lệ (cần 8, 12 hoặc 13 chữ số)'), findsOneWidget);
      expect(openedFood, isNull);
    });

    testWidgets('tapping simulation chip triggers 1-tap lookup and calls onOpenFood for existing product', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Nhập số'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('chip_simulation_original')));
      // Allow async lookup to complete and pump frame
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(openedFood, isNotNull);
      expect(openedFood!.name, 'Bánh nguyên bản test');
      expect(openedFood!.barcode, '8934567890456');
    });

    testWidgets('tapping 404 test chip navigates to LookupNotFoundPage with dynamic barcode and rescan button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Nhập số'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('chip_simulation_404')));
      // Allow async lookup to complete
      await tester.pump();
      // Pump transition animation to LookupNotFoundPage
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LookupNotFoundPage), findsOneWidget);
      expect(find.byKey(const Key('not_found_barcode_text')), findsOneWidget);
      expect(find.text('0000000000000'), findsOneWidget);
      expect(find.text('Chưa tìm thấy sản phẩm\nnày'), findsOneWidget);

      // Scroll down to reveal rescan button in ListView
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Rescan button pops back to ScanPage
      await tester.tap(find.byKey(const Key('not_found_rescan_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LookupNotFoundPage), findsNothing);
      expect(find.byType(ScanPage), findsOneWidget);
    });

    testWidgets('network error routes to LookupErrorPage with dynamic barcode and retry button', (tester) async {
      mockRepo.simulateNetworkError = true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Nhập số'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('scan_barcode_input_field')), '8934567890123');
      await tester.tap(find.byKey(const Key('scan_manual_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LookupErrorPage), findsOneWidget);
      expect(find.byKey(const Key('error_barcode_text')), findsOneWidget);
      expect(find.text('8934567890123'), findsOneWidget);
      expect(find.text('Chưa kết nối được với\nnguồn dữ liệu'), findsOneWidget);

      // Scroll down to reveal retry button in ListView
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      // Clear error for retry attempt so retry succeeds
      mockRepo.simulateNetworkError = false;

      await tester.tap(find.byKey(const Key('error_retry_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LookupErrorPage), findsNothing);
      expect(openedFood, isNotNull);
    });
  });
}
