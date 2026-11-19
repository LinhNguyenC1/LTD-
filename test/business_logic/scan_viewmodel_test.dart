import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/business_logic/rules/nutrition_evaluator.dart';
import 'package:an_lanh/business_logic/viewmodels/scan_viewmodel.dart';
import 'package:an_lanh/data/local/daos/history_dao.dart';
import 'package:an_lanh/data/local/daos/nutrition_dao.dart';
import 'package:an_lanh/data/local/daos/product_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/product_nutrition.dart';
import 'package:an_lanh/data/models/scan_history_item.dart';
import 'package:an_lanh/data/remote/open_food_facts_api.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import 'package:an_lanh/data/repositories/profile_repository.dart';
import 'package:an_lanh/core/services/notification_service.dart';
import '../helpers/test_database_helper.dart';

class FakeProductRepository extends ProductRepository {
  final Map<String, CachedProduct> products = {};
  final Map<int, ProductNutrition> nutrition = {};
  bool throwNetworkError = false;
  bool throwTimeout = false;
  int lookupCount = 0;

  @override
  Future<CachedProduct?> getProductByBarcode(String barcode) async {
    lookupCount++;
    if (throwNetworkError) {
      throw const SocketException('Connection refused');
    }
    if (throwTimeout) {
      throw TimeoutException('Request timed out');
    }
    return products[barcode];
  }

  @override
  Future<ProductNutrition?> getNutritionByProductId(int productId) async {
    return nutrition[productId];
  }
}

class FakeHistoryDao extends HistoryDao {
  final List<ScanHistoryItem> insertedItems = [];

  @override
  Future<int> insertHistoryItem(ScanHistoryItem item) async {
    insertedItems.add(item);
    return insertedItems.length;
  }

  @override
  Future<List<ScanHistoryItem>> getAllHistory() async {
    return List.from(insertedItems);
  }
}

void main() {
  late FakeProductRepository fakeRepo;
  late FakeHistoryDao fakeHistory;
  late NotificationService fakeNotif;
  late Database db;
  late ProfileRepository profileRepo;
  late ScanViewModel vm;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: true);
    fakeRepo = FakeProductRepository();
    fakeHistory = FakeHistoryDao();
    fakeNotif = NotificationService.forTest();
    await fakeNotif.initialize();
    profileRepo = ProfileRepository();

    vm = ScanViewModel(
      productRepository: fakeRepo,
      profileRepository: profileRepo,
      historyDao: fakeHistory,
      notificationService: fakeNotif,
    );
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
    fakeNotif.reset();
  });

  group('ScanViewModel Unit Tests', () {
    test('initial state is idle and values are empty/null', () {
      expect(vm.status, ScanStatus.idle);
      expect(vm.isLoading, isFalse);
      expect(vm.isSuccess, isFalse);
      expect(vm.isNotFound, isFalse);
      expect(vm.scannedProduct, isNull);
      expect(vm.scannedNutrition, isNull);
      expect(vm.allergenViolations, isEmpty);
      expect(vm.nutritionViolations, isEmpty);
      expect(vm.errorMessage, isNull);
      expect(vm.isInFlight, isFalse);
    });

    test('validates barcode: rejects invalid formats and sets invalidBarcode status', () async {
      expect(vm.validateBarcode(null), contains('Vui lòng nhập mã vạch'));
      expect(vm.validateBarcode(''), contains('Vui lòng nhập mã vạch'));
      expect(vm.validateBarcode('123'), contains('không hợp lệ'));
      expect(vm.validateBarcode('8934567890123'), isNull);

      final success = await vm.lookupBarcode('12345');
      expect(success, isFalse);
      expect(vm.status, ScanStatus.invalidBarcode);
      expect(vm.isInvalidBarcode, isTrue);
      expect(vm.errorMessage, contains('không hợp lệ'));
    });

    test('lookupBarcode handles product not found', () async {
      final success = await vm.lookupBarcode('0000000000000');
      expect(success, isFalse);
      expect(vm.status, ScanStatus.notFound);
      expect(vm.isNotFound, isTrue);
      expect(vm.errorMessage, contains('Không tìm thấy'));
      expect(vm.scannedProduct, isNull);
    });

    test('lookupBarcode handles network error / SocketException', () async {
      fakeRepo.throwNetworkError = true;
      final success = await vm.lookupBarcode('8934567890123');
      expect(success, isFalse);
      expect(vm.status, ScanStatus.networkError);
      expect(vm.isNetworkError, isTrue);
      expect(vm.errorMessage, contains('Lỗi kết nối'));
    });

    test('lookupBarcode handles timeout exception', () async {
      fakeRepo.throwTimeout = true;
      final success = await vm.lookupBarcode('8934567890123');
      expect(success, isFalse);
      expect(vm.status, ScanStatus.networkError);
      expect(vm.isNetworkError, isTrue);
      expect(vm.errorMessage, contains('Timeout'));
    });

    test('lookupBarcode handles successful safe scan: evaluates rules, logs history, fires notifications', () async {
      // Setup product
      const barcode = '8934567890456';
      final product = CachedProduct(
        id: 10,
        barcode: barcode,
        productName: 'Bánh yến mạch nguyên bản',
        brand: 'An Mộc',
        ingredientsText: 'Yến mạch 65%, bột mì nguyên cám 20%, muối 0.12%',
        cachedAt: DateTime.now().toIso8601String(),
      );
      final nutrition = ProductNutrition(
        id: 10,
        productId: 10,
        nutritionData: {'sugars': 4.2, 'salt': 0.12},
      );
      fakeRepo.products[barcode] = product;
      fakeRepo.nutrition[10] = nutrition;

      // Profile: peanut allergy, 15g sugar target
      await profileRepo.saveUserProfile(
        name: 'Người dùng test',
        allergens: ['peanut'],
        nutritionTargets: {'sugars': 15.0},
      );

      final success = await vm.lookupBarcode(barcode);
      expect(success, isTrue);
      expect(vm.status, ScanStatus.success);
      expect(vm.isSuccess, isTrue);
      expect(vm.scannedProduct, isNotNull);
      expect(vm.scannedProduct!.productName, 'Bánh yến mạch nguyên bản');
      expect(vm.allergenViolations, isEmpty);
      expect(vm.nutritionViolations, isEmpty);

      // Verify history logged
      expect(fakeHistory.insertedItems.length, 1);
      final historyItem = fakeHistory.insertedItems.first;
      expect(historyItem.productId, 10);
      expect(historyItem.evaluationStatus, 'SAFE');

      // Verify notifications
      final notifications = fakeNotif.deliveredNotifications;
      expect(notifications.any((n) => n.id == 300), isTrue); // Safe scan notification
      expect(notifications.any((n) => n.id == 301), isTrue); // Scan completed notification
    });

    test('lookupBarcode detects allergen violation: logs VIOLATION and fires allergen alert', () async {
      const barcode = '8934567890123';
      final product = CachedProduct(
        id: 20,
        barcode: barcode,
        productName: 'Bánh yến mạch cacao',
        brand: 'Mộc Hạt',
        ingredientsText: 'Yến mạch 45%, bột sữa 8%, cacao 4%, chất nhũ hóa đậu nành',
        cachedAt: DateTime.now().toIso8601String(),
      );
      fakeRepo.products[barcode] = product;

      // User has milk and soy allergies
      await profileRepo.saveUserProfile(
        name: 'Dị ứng test',
        allergens: ['milk', 'soy'],
        nutritionTargets: {},
      );

      final success = await vm.lookupBarcode(barcode);
      expect(success, isTrue);
      expect(vm.allergenViolations, contains('milk'));
      expect(vm.allergenViolations, contains('soy'));

      // Check history
      expect(fakeHistory.insertedItems.last.evaluationStatus, 'VIOLATION');
      expect(fakeHistory.insertedItems.last.violationReasons, contains('milk'));

      // Check notification
      final notif = fakeNotif.deliveredNotifications.firstWhere((n) => n.channelId == 'food_alerts');
      expect(notif.title, contains('Cảnh báo'));
      expect(notif.body, contains('milk'));
    });

    test('lookupBarcode detects nutrition target warning: fires nutrition alert', () async {
      const barcode = '3017620422003';
      final product = CachedProduct(
        id: 30,
        barcode: barcode,
        productName: 'Bánh ngọt ăn vặt',
        cachedAt: DateTime.now().toIso8601String(),
      );
      final nutrition = ProductNutrition(
        id: 30,
        productId: 30,
        nutritionData: {'sugars': 45.0},
      );
      fakeRepo.products[barcode] = product;
      fakeRepo.nutrition[30] = nutrition;

      // User limit is 10g sugars
      await profileRepo.saveUserProfile(
        name: 'Giảm đường',
        allergens: [],
        nutritionTargets: {'sugars': 10.0},
      );

      final success = await vm.lookupBarcode(barcode);
      expect(success, isTrue);
      expect(vm.allergenViolations, isEmpty);
      expect(vm.nutritionViolations, isNotEmpty);
      expect(fakeHistory.insertedItems.last.evaluationStatus, 'WARNING');

      final nutAlert = fakeNotif.deliveredNotifications.firstWhere((n) => n.id == 102);
      expect(nutAlert.title, contains('Cảnh báo dinh dưỡng'));
    });

    test('retry executes lookup with last scanned barcode', () async {
      const barcode = '8934567890456';
      fakeRepo.products[barcode] = CachedProduct(
        id: 1,
        barcode: barcode,
        productName: 'Bánh test',
        cachedAt: DateTime.now().toIso8601String(),
      );

      await vm.lookupBarcode(barcode);
      expect(fakeRepo.lookupCount, 1);

      await vm.retry();
      expect(fakeRepo.lookupCount, 2);
    });

    test('setManualBarcode and reset update state and notify', () {
      bool notified = false;
      vm.addListener(() => notified = true);

      vm.setManualBarcode('8930000000123');
      expect(vm.manualBarcode, '8930000000123');
      expect(notified, isTrue);

      notified = false;
      vm.reset();
      expect(vm.status, ScanStatus.idle);
      expect(notified, isTrue);
    });

    test('end-to-end network dropout in ProductRepository propagates to ScanStatus.networkError', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Network connection failed');
      });
      final offApi = OpenFoodFactsApi(client: mockClient);
      final realProductRepo = ProductRepository(
        productDao: ProductDao(),
        nutritionDao: NutritionDao(),
        offClient: offApi,
      );

      final realVm = ScanViewModel(
        productRepository: realProductRepo,
        profileRepository: profileRepo,
        historyDao: fakeHistory,
        notificationService: fakeNotif,
      );

      final success = await realVm.lookupBarcode('8931112223334');
      expect(success, isFalse);
      expect(realVm.status, ScanStatus.networkError);
      expect(realVm.isNetworkError, isTrue);
      expect(realVm.isNotFound, isFalse);
      expect(realVm.errorMessage, contains('Lỗi kết nối mạng'));
    });

    test('end-to-end HTTP 500 server error propagates to ScanStatus.networkError', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': 0,
          'error': 'Internal server error',
        });
        return http.Response(body, 500, headers: {'content-type': 'application/json'});
      });
      final offApi = OpenFoodFactsApi(client: mockClient);
      final realProductRepo = ProductRepository(
        productDao: ProductDao(),
        nutritionDao: NutritionDao(),
        offClient: offApi,
      );

      final realVm = ScanViewModel(
        productRepository: realProductRepo,
        profileRepository: profileRepo,
        historyDao: fakeHistory,
        notificationService: fakeNotif,
      );

      final success = await realVm.lookupBarcode('8931112223334');
      expect(success, isFalse);
      expect(realVm.status, ScanStatus.networkError);
      expect(realVm.isNetworkError, isTrue);
      expect(realVm.isNotFound, isFalse);
    });

    test('end-to-end string-formatted nutriments evaluate properly without formatError', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Sản phẩm dinh dưỡng string',
            'brands': 'Test Brand',
            'ingredients_text': 'Đường, Nước',
            'nutriments': {
              'sugars_100g': '25.0',
              'fat_100g': '5.0',
              'energy-kcal_100g': '150',
            },
          },
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });
      final offApi = OpenFoodFactsApi(client: mockClient);
      final realProductRepo = ProductRepository(
        productDao: ProductDao(),
        nutritionDao: NutritionDao(),
        offClient: offApi,
      );

      await profileRepo.saveUserProfile(
        name: 'Người ăn kiêng',
        allergens: [],
        nutritionTargets: {'sugars': 10.0},
      );

      final realVm = ScanViewModel(
        productRepository: realProductRepo,
        profileRepository: profileRepo,
        historyDao: fakeHistory,
        notificationService: fakeNotif,
      );

      final success = await realVm.lookupBarcode('8939998887776');
      expect(success, isTrue);
      expect(realVm.status, ScanStatus.success);
      expect(realVm.isSuccess, isTrue);
      expect(realVm.nutritionViolations, isNotEmpty);
      expect(realVm.nutritionViolations.first, contains('sugars'));
      expect(realVm.nutritionViolations.first, contains('25'));
    });

    test('NutritionEvaluator handles string numbers and whitespace safely without throwing', () {
      final targets = {'sugars': 10.0, 'fat': 5.0, 'salt': 1.0};
      final actualData = {
        'sugars_100g': ' 15.5 ',
        'fat': '3.2',
        'salt_100g': '0.5',
      };

      final violations = NutritionEvaluator.evaluate(
        targets: targets,
        actualData: actualData,
      );

      expect(violations.length, 1);
      expect(violations.first, contains('sugars'));
      expect(violations.first, contains('15.5'));
    });
  });
}
