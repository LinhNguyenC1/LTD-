import 'package:flutter_test/flutter_test.dart';
import '../helpers/mock_notification_service.dart';

void main() {
  late MockNotificationService notificationService;

  setUp(() {
    notificationService = MockNotificationService();
  });

  tearDown(() {
    notificationService.reset();
  });

  group('Tier 1: Notification Coverage Tests', () {
    test('T1_NOTIF_01: Notification service initializes cleanly with food_alerts and app_events channels', () async {
      expect(notificationService.isInitialized, isFalse);

      await notificationService.initialize();

      expect(notificationService.isInitialized, isTrue);
      expect(notificationService.registeredChannels, contains('food_alerts'));
      expect(notificationService.registeredChannels, contains('app_events'));
    });

    test('T1_NOTIF_02: User login event triggers welcome notification on app_events channel', () async {
      await notificationService.initialize();
      await notificationService.showLoginWelcome('Nguyễn Văn A');

      expect(notificationService.deliveredNotifications.length, 1);
      final notif = notificationService.deliveredNotifications.first;

      expect(notif.id, 200);
      expect(notif.channelId, 'app_events');
      expect(notif.title, contains('Nguyễn Văn A'));
      expect(notif.body, contains('Đăng nhập thành công'));
    });

    test('T1_NOTIF_03: User registration event triggers welcome notification on app_events channel', () async {
      await notificationService.initialize();
      await notificationService.showRegisterWelcome('Thành Viên Mới');

      expect(notificationService.deliveredNotifications.length, 1);
      final notif = notificationService.deliveredNotifications.first;

      expect(notif.id, 201);
      expect(notif.channelId, 'app_events');
      expect(notif.title, contains('Chào mừng'));
      expect(notif.body, contains('Thành Viên Mới'));
    });

    test('T1_NOTIF_04: Scan result with allergen violation triggers high-priority alert on food_alerts channel', () async {
      await notificationService.initialize();
      await notificationService.showAllergenAlert(
        productName: 'Bánh yến mạch cacao',
        allergenName: 'bột sữa',
      );

      expect(notificationService.deliveredNotifications.length, 1);
      final notif = notificationService.deliveredNotifications.first;

      expect(notif.id, 100);
      expect(notif.channelId, 'food_alerts');
      expect(notif.title, contains('Cảnh báo dị ứng'));
      expect(notif.title, contains('Bánh yến mạch cacao'));
      expect(notif.body, contains('bột sữa'));
    });

    test('T1_NOTIF_05: Safe scan evaluation dispatches informational notification on app_events', () async {
      await notificationService.initialize();
      await notificationService.showSafeScanNotification('Bánh yến mạch nguyên bản');

      expect(notificationService.deliveredNotifications.length, 1);
      final notif = notificationService.deliveredNotifications.first;

      expect(notif.id, 300);
      expect(notif.channelId, 'app_events');
      expect(notif.title, contains('Sản phẩm an toàn'));
      expect(notif.title, contains('Bánh yến mạch nguyên bản'));
      expect(notif.body, contains('Không phát hiện vi phạm'));
    });
  });
}
