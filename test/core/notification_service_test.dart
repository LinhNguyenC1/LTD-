import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:an_lanh/core/services/notification_service.dart';
import 'package:an_lanh/business_logic/viewmodels/auth_viewmodel.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class ThrowingNotificationService extends NotificationService {
  ThrowingNotificationService() : super.forTest();

  @override
  Future<void> showLoginWelcome(String username) async {
    throw Exception('Platform notification error');
  }

  @override
  Future<void> showRegisterWelcome(String username) async {
    throw Exception('Platform notification error');
  }
}

void main() {
  late NotificationService service;

  setUp(() {
    service = NotificationService.instance;
    service.reset();
  });

  tearDown(() {
    service.reset();
  });

  group('NotificationService - Singleton & Setup', () {
    test('instance getter and factory constructor return identical singleton', () {
      final s1 = NotificationService.instance;
      final s2 = NotificationService();
      expect(identical(s1, s2), isTrue);
    });

    test('initialize populates default channels and sets isInitialized', () async {
      expect(service.isInitialized, isFalse);
      await service.initialize();
      expect(service.isInitialized, isTrue);
      expect(service.registeredChannels, contains('food_alerts'));
      expect(service.registeredChannels, contains('app_events'));
    });

    test('headless and test detection property is true in test environment', () {
      expect(service.isHeadlessOrUnsupportedPlatform, isTrue);
    });

    test('custom instance can be injected for testing', () {
      final original = NotificationService.instance;
      final custom = NotificationService.forTest();
      NotificationService.instance = custom;
      expect(NotificationService.instance, equals(custom));
      NotificationService.instance = original;
    });
  });

  group('NotificationService - Channels and Routing', () {
    test('showNotification with food_alerts channel records properly', () async {
      await service.showNotification(
        id: 1,
        title: 'Cảnh báo',
        body: 'Thực phẩm hết hạn',
        channelId: 'food_alerts',
      );

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(1));
      expect(notif.title, equals('Cảnh báo'));
      expect(notif.body, equals('Thực phẩm hết hạn'));
      expect(notif.channelId, equals('food_alerts'));
      expect(service.activeNotificationsById[1], equals(notif));
    });

    test('showNotification with null channelId defaults to app_events', () async {
      await service.showNotification(
        id: 2,
        title: 'Thông báo chung',
        body: 'Nội dung cập nhật',
      );

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.channelId, equals('app_events'));
    });
  });

  group('NotificationService - Predefined Events', () {
    test('showAllergenAlert dispatches with ID 100 on food_alerts channel', () async {
      await service.showAllergenAlert(
        productName: 'Bánh mì ngũ cốc',
        allergenName: 'Đậu phộng',
      );

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(100));
      expect(notif.channelId, equals('food_alerts'));
      expect(notif.title, equals('Cảnh báo dị ứng: Bánh mì ngũ cốc'));
      expect(notif.body, contains('Đậu phộng'));
      expect(notif.body, contains('vi phạm hồ sơ ăn uống'));
    });

    test('showAggregatedAllergenAlert joins multiple allergens on food_alerts channel', () async {
      await service.showAggregatedAllergenAlert(
        productName: 'Sốt Mayonnaise',
        allergens: ['Trứng', 'Đậu nành', 'Mù tạt'],
      );

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(101));
      expect(notif.channelId, equals('food_alerts'));
      expect(notif.title, equals('Cảnh báo đa dị ứng: Sốt Mayonnaise'));
      expect(notif.body, contains('Trứng, Đậu nành, Mù tạt'));
    });

    test('showNutritionAlert dispatches with ID 102 on food_alerts channel', () async {
      await service.showNutritionAlert(
        productName: 'Nước tăng lực',
        warningDetails: 'Đường (55g) vượt ngưỡng mục tiêu (25g)',
      );

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(102));
      expect(notif.channelId, equals('food_alerts'));
      expect(notif.title, equals('Cảnh báo dinh dưỡng: Nước tăng lực'));
      expect(notif.body, contains('Đường (55g) vượt ngưỡng mục tiêu (25g)'));
    });

    test('showAuthNotification dispatches custom auth event on app_events', () async {
      await service.showAuthNotification(
        title: 'Xác thực hai yếu tố',
        body: 'Mã xác thực đã được gửi',
        id: 205,
      );

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(205));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, equals('Xác thực hai yếu tố'));
      expect(notif.body, equals('Mã xác thực đã được gửi'));
    });

    test('showLoginWelcome dispatches with ID 200 on app_events channel', () async {
      await service.showLoginWelcome('lan_huong');

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(200));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, equals('Chào mừng trở lại, lan_huong!'));
      expect(notif.body, contains('Đăng nhập thành công vào Ăn Lành'));
    });

    test('showRegisterWelcome dispatches with ID 201 on app_events channel', () async {
      await service.showRegisterWelcome('minh_tuan');

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(201));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, equals('Chào mừng thành viên mới!'));
      expect(notif.body, contains('minh_tuan'));
      expect(notif.body, contains('kích hoạt thành công'));
    });

    test('showSafeScanNotification dispatches with ID 300 on app_events channel', () async {
      await service.showSafeScanNotification('Táo Envy Mỹ');

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(300));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, equals('Sản phẩm an toàn: Táo Envy Mỹ'));
      expect(notif.body, contains('Không phát hiện vi phạm'));
    });

    test('showScanCompletedNotification dispatches with ID 301 on app_events channel', () async {
      await service.showScanCompletedNotification('Sữa chua nha đam');

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(301));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, equals('Đã quét: Sữa chua nha đam'));
      expect(notif.body, contains('lưu vào lịch sử'));
    });
  });

  group('NotificationService - Boundary & Corner Cases', () {
    test('body exceeding maxBodyLength (500 chars) truncates with ellipsis', () async {
      final longBody = 'A' * 600;
      await service.showNotification(
        id: 10,
        title: 'Tin nhắn dài',
        body: longBody,
      );

      final notif = service.deliveredNotifications.first;
      expect(notif.body.length, equals(503));
      expect(notif.body.startsWith('A' * 500), isTrue);
      expect(notif.body.endsWith('...'), isTrue);
    });

    test('consecutive notifications with identical ID overwrite active map but keep history', () async {
      await service.showNotification(id: 99, title: 'Lần 1', body: 'Nội dung 1');
      await service.showNotification(id: 99, title: 'Lần 2', body: 'Nội dung 2');

      expect(service.deliveredNotifications.length, equals(2));
      expect(service.activeNotificationsById.length, equals(1));
      expect(service.activeNotificationsById[99]!.title, equals('Lần 2'));
      expect(service.activeNotificationsById[99]!.body, equals('Nội dung 2'));
    });

    test('when permissionGranted is false showNotification does nothing', () async {
      service.permissionGranted = false;
      await service.showNotification(id: 50, title: 'Bị chặn', body: 'Không hiển thị');

      expect(service.deliveredNotifications, isEmpty);
      expect(service.activeNotificationsById, isEmpty);
    });

    test('reset and resetForTest clear all state and reset permission', () async {
      service.permissionGranted = false;
      await service.showNotification(id: 1, title: 'T', body: 'B');
      service.permissionGranted = true;
      await service.showNotification(id: 2, title: 'T2', body: 'B2');
      expect(service.deliveredNotifications.length, equals(1));

      service.reset();
      expect(service.deliveredNotifications, isEmpty);
      expect(service.activeNotificationsById, isEmpty);
      expect(service.permissionGranted, isTrue);

      await service.showNotification(id: 3, title: 'T3', body: 'B3');
      expect(service.deliveredNotifications.length, equals(1));
      service.resetForTest();
      expect(service.deliveredNotifications, isEmpty);
    });

    test('RecordedNotification toString formats properly', () {
      final notif = RecordedNotification(
        id: 5,
        title: 'T',
        body: 'B',
        channelId: 'C',
        timestamp: DateTime(2026, 1, 1),
      );
      expect(notif.toString(), equals('RecordedNotification(id: 5, channel: C, title: T, body: B)'));
    });
  });

  group('AuthViewModel - Notification Integration', () {
    late MockAuthRepository mockAuthRepo;
    late AuthViewModel authViewModel;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      authViewModel = AuthViewModel(
        authRepository: mockAuthRepo,
        notificationService: service,
      );
    });

    test('successful login triggers welcome notification', () async {
      final user = User(
        id: 1,
        username: 'nguyen_van_a',
        email: 'a@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockAuthRepo.login('a@example.com', 'password123'))
          .thenAnswer((_) async => user);

      final success = await authViewModel.login('a@example.com', 'password123');
      expect(success, isTrue);

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(200));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, contains('nguyen_van_a'));
    });

    test('failed login does not trigger welcome notification', () async {
      when(() => mockAuthRepo.login('a@example.com', 'wrong_pass'))
          .thenAnswer((_) async => null);

      final success = await authViewModel.login('a@example.com', 'wrong_pass');
      expect(success, isFalse);
      expect(service.deliveredNotifications, isEmpty);
    });

    test('successful registration triggers new user welcome notification', () async {
      final user = User(
        id: 2,
        username: 'le_thi_b',
        email: 'b@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockAuthRepo.register('b@example.com', 'password123', 'le_thi_b'))
          .thenAnswer((_) async => true);
      when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => user);

      final success = await authViewModel.register(
        email: 'b@example.com',
        password: 'password123',
        name: 'le_thi_b',
        confirmPassword: 'password123',
      );
      expect(success, isTrue);

      expect(service.deliveredNotifications.length, equals(1));
      final notif = service.deliveredNotifications.first;
      expect(notif.id, equals(201));
      expect(notif.channelId, equals('app_events'));
      expect(notif.title, contains('Chào mừng thành viên mới'));
      expect(notif.body, contains('le_thi_b'));
    });

    test('failed registration does not trigger welcome notification', () async {
      when(() => mockAuthRepo.register(any(), any(), any()))
          .thenAnswer((_) async => false);

      final success = await authViewModel.register(
        email: 'existing@example.com',
        password: 'password123',
        name: 'existing_user',
        confirmPassword: 'password123',
      );
      expect(success, isFalse);
      expect(service.deliveredNotifications, isEmpty);
    });

    test('login succeeds even if notification service throws error', () async {
      final throwingService = ThrowingNotificationService();
      final vm = AuthViewModel(
        authRepository: mockAuthRepo,
        notificationService: throwingService,
      );

      final user = User(
        id: 3,
        username: 'user_resilient',
        email: 'resilient@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockAuthRepo.login('resilient@example.com', 'password123'))
          .thenAnswer((_) async => user);

      final success = await vm.login('resilient@example.com', 'password123');
      expect(success, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.currentUser?.username, equals('user_resilient'));
    });

    test('registration succeeds even if notification service throws error', () async {
      final throwingService = ThrowingNotificationService();
      final vm = AuthViewModel(
        authRepository: mockAuthRepo,
        notificationService: throwingService,
      );

      final user = User(
        id: 4,
        username: 'user_resilient_reg',
        email: 'resilient_reg@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockAuthRepo.register('resilient_reg@example.com', 'password123', 'user_resilient_reg'))
          .thenAnswer((_) async => true);
      when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => user);

      final success = await vm.register(
        email: 'resilient_reg@example.com',
        password: 'password123',
        name: 'user_resilient_reg',
        confirmPassword: 'password123',
      );
      expect(success, isTrue);
      expect(vm.isAuthenticated, isTrue);
    });
  });
}
