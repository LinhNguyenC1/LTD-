import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:an_lanh/business_logic/viewmodels/scan_viewmodel.dart';
import 'package:an_lanh/core/services/notification_service.dart';
import 'package:an_lanh/data/local/daos/history_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/cached_product_adapter.dart';
import 'package:an_lanh/data/models/food.dart';
import 'package:an_lanh/data/models/product_nutrition.dart';
import 'package:an_lanh/data/models/user_profile.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import 'package:an_lanh/data/repositories/profile_repository.dart';
import 'package:an_lanh/presentation/screens/product/detail_page.dart';
import 'package:an_lanh/presentation/screens/scan/lookup_error_page.dart';
import 'package:an_lanh/presentation/screens/scan/lookup_not_found_page.dart';
import 'package:an_lanh/presentation/screens/scan/scan_page.dart';

class _StubProductRepo extends ProductRepository {
  final Map<String, CachedProduct> products = {
    '12345670': CachedProduct(
      id: 1,
      barcode: '12345670',
      productName: 'Sữa hạt biên 8 số',
      brand: 'An Mộc',
      ingredientsText: 'Hạnh nhân, bột sữa 5%, nước',
      nutriscoreGrade: 'b',
      cachedAt: '2026-11-26T10:00:00',
    ),
    '012345678905': CachedProduct(
      id: 2,
      barcode: '012345678905',
      productName: 'Ngũ cốc UPC-A 12 số',
      brand: 'Mộc Hạt',
      ingredientsText: 'Yến mạch nguyên chất, mật ong',
      nutriscoreGrade: 'a',
      cachedAt: '2026-11-26T10:00:00',
    ),
    '8934567890123': CachedProduct(
      id: 3,
      barcode: '8934567890123',
      productName: 'Bánh yến mạch cacao EAN-13',
      brand: 'Mộc Hạt',
      ingredientsText: 'Yến mạch 45%, bột sữa 8%, cacao 4%',
      nutriscoreGrade: 'c',
      cachedAt: '2026-11-26T10:00:00',
    ),
  };

  @override
  Future<CachedProduct?> getProductByBarcode(String barcode) async {
    return products[barcode];
  }

  @override
  Future<ProductNutrition?> getNutritionByProductId(int productId) async {
    return ProductNutrition(
      id: productId,
      productId: productId,
      nutritionData: {'sugars': 18.0, 'salt': 0.42},
    );
  }
}

class _StubProfileRepo extends ProfileRepository {
  @override
  Future<UserProfile?> fetchUserProfile([int? userId]) async => UserProfile(
        id: 1,
        name: 'Khiêm Test',
        allergens: ['milk'],
        nutritionTargets: {'sugars': 10.0},
        updatedAt: '2026-11-26',
      );
}

class _StubHistoryDao extends HistoryDao {
  @override
  Future<int> insertHistoryItem(item) async => 1;
}

void main() {
  Future<void> setSize(WidgetTester tester, double w, double h) async {
    tester.view.physicalSize = Size(w, h);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  ScanViewModel makeVm() => ScanViewModel(
        productRepository: _StubProductRepo(),
        profileRepository: _StubProfileRepo(),
        historyDao: _StubHistoryDao(),
        notificationService: NotificationService.forTest(),
      );

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(800, 1280),
  ]) {
    testWidgets('ScanPage renders all modes without overflow at ${size.width}x${size.height}', (tester) async {
      await setSize(tester, size.width, size.height);
      final vm = makeVm();
      await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<ScanViewModel>.value(
          value: vm,
          child: ScanPage(onOpenFood: (_) {}),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Thành phần'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Đưa bảng thành phần vào khung OCR'), findsOneWidget);

      await tester.tap(find.text('Nhập số'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('scan_barcode_input_field')), findsOneWidget);
    });

    testWidgets('DetailPage renders cleanly on scroll without overflow at ${size.width}x${size.height}', (tester) async {
      await setSize(tester, size.width, size.height);
      await tester.pumpWidget(const MaterialApp(
        home: DetailPage(food: foodCocoa),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 200));
    });
  }

  testWidgets('LookupErrorPage & LookupNotFoundPage render cleanly at 320x568 with 1.25x font scale', (tester) async {
    await setSize(tester, 320, 568);
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(1.25)),
      child: MaterialApp(home: LookupErrorPage()),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(1.25)),
      child: MaterialApp(home: LookupNotFoundPage()),
    ));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('Manual input validates empty, whitespace, boundary 7/8/12/13/14 digits accurately', (tester) async {
    final vm = makeVm();
    Food? opened;
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<ScanViewModel>.value(
        value: vm,
        child: ScanPage(onOpenFood: (f) => opened = f),
      ),
    ));
    await tester.tap(find.text('Nhập số'));
    await tester.pump(const Duration(milliseconds: 300));

    // Empty input
    await tester.enterText(find.byKey(const Key('scan_barcode_input_field')), '   ');
    await tester.tap(find.byKey(const Key('scan_manual_submit_button')));
    await tester.pump();
    expect(find.text('Vui lòng nhập mã vạch'), findsOneWidget);
    expect(opened, isNull);

    // Invalid boundary: 7 digits
    await tester.enterText(find.byKey(const Key('scan_barcode_input_field')), '1234567');
    await tester.tap(find.byKey(const Key('scan_manual_submit_button')));
    await tester.pump();
    expect(find.text('Mã vạch không hợp lệ (cần 8, 12 hoặc 13 chữ số)'), findsOneWidget);

    // Invalid boundary: 14 digits
    await tester.enterText(find.byKey(const Key('scan_barcode_input_field')), '12345678901234');
    await tester.tap(find.byKey(const Key('scan_manual_submit_button')));
    await tester.pump();
    expect(find.text('Mã vạch không hợp lệ (cần 8, 12 hoặc 13 chữ số)'), findsOneWidget);

    // Valid EAN-8 with surrounding spaces
    await tester.enterText(find.byKey(const Key('scan_barcode_input_field')), ' 12345670 ');
    await tester.tap(find.byKey(const Key('scan_manual_submit_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(opened, isNotNull);
    expect(opened!.barcode, '12345670');
    expect(opened!.result, Result.bad);
    expect(opened!.allergenWarning, contains('milk'));
    expect(opened!.sugar, '18.0 g');
    expect(opened!.salt, '0.42 g');
  });

  testWidgets('CachedProductAdapter never leaves empty metrics on DetailPage', (tester) async {
    final p = CachedProduct(
      id: 99,
      barcode: '8934567890999',
      productName: 'Sản phẩm test adapter',
      cachedAt: '2026-11-26',
    );
    final food = p.toFood();
    await tester.pumpWidget(MaterialApp(home: DetailPage(food: food)));
    await tester.pump();

    expect(find.text(''), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pump();
    expect(find.text('Chưa có dữ liệu'), findsWidgets);
  });
}
