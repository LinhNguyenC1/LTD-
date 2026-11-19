import 'package:flutter_test/flutter_test.dart';
import '../helpers/mock_notification_service.dart';

void main() {
  late MockNotificationService notificationService;

  setUp(() async {
    notificationService = MockNotificationService();
    await notificationService.initialize();
  });

  tearDown(() {
    notificationService.reset();
  });

  group('Tier 2: Notification Boundary & Corner Cases', () {
    test('T2_NOTIF_01: Rapid consecutive notifications with identical ID overwrite rather than leaking memory', () async {
      // Dispatch 10 rapid notifications with identical ID
      for (int i = 1; i <= 10; ++i) {
        await notificationService.showNotification(
          id: 50,
          title: 'Cập nhật quét lần $i',
          body: 'Đang xử lý sản phẩm phiên bản $i',
          channelId: 'food_alerts',
        );
      }

      // Active notifications map should contain exactly 1 entry for ID 50
      expect(notificationService.activeNotificationsById.containsKey(50), isTrue);
      expect(notificationService.activeNotificationsById.length, 1);
      expect(
        notificationService.activeNotificationsById[50]!.title,
        'Cập nhật quét lần 10',
      );
    });

    test('T2_NOTIF_02: Extremely long notification text (1000+ chars) truncates safely without crashing payload', () async {
      final longIngredients = 'Thành phần: đường, sữa, yến mạch, hương vani tự nhiên, chất điều vị, chất bảo quản, màu thực phẩm tổng hợp ' * 15;
      expect(longIngredients.length, greaterThan(1000));

      await notificationService.showNotification(
        id: 77,
        title: 'Cảnh báo thành phần dài',
        body: longIngredients,
        channelId: 'food_alerts',
      );

      final notif = notificationService.activeNotificationsById[77];
      expect(notif, isNotNull);
      expect(notif!.body.length, lessThanOrEqualTo(MockNotificationService.maxBodyLength + 3));
      expect(notif.body.endsWith('...'), isTrue);
    });

    test('T2_NOTIF_03: Product violating multiple allergens simultaneously aggregates violations into a single notification', () async {
      final multipleAllergens = ['bột sữa', 'đậu phộng', 'lecithin đậu nành', 'gluten'];

      await notificationService.showAggregatedAllergenAlert(
        productName: 'Bánh tổng hợp hạt & sữa',
        allergens: multipleAllergens,
      );

      final notif = notificationService.activeNotificationsById[101];
      expect(notif, isNotNull);
      expect(notif!.channelId, 'food_alerts');
      expect(notif.title, contains('Bánh tổng hợp hạt & sữa'));
      expect(notif.body, contains('bột sữa, đậu phộng, lecithin đậu nành, gluten'));
    });

    test('T2_NOTIF_04: Notification dispatched when system permission is denied does not throw unhandled exception', () async {
      notificationService.permissionGranted = false;

      // Must complete without throwing any exception
      await expectLater(
        notificationService.showNotification(
          id: 99,
          title: 'Thông báo bị từ chối quyền',
          body: 'Quyền thông báo chưa được người dùng cấp phép trên Android 13+',
        ),
        completes,
      );

      // Notification should not be registered as active
      expect(notificationService.activeNotificationsById.containsKey(99), isFalse);
    });

    test('T2_NOTIF_05: Notification trigger during headless background state completes without UI thread dependency', () async {
      notificationService.isHeadless = true;

      await expectLater(
        notificationService.showNotification(
          id: 105,
          title: 'Tác vụ chạy nền',
          body: 'Đồng bộ dữ liệu thành phần hoàn tất ở chế độ nền.',
          channelId: 'app_events',
        ),
        completes,
      );

      expect(notificationService.activeNotificationsById.containsKey(105), isTrue);
    });
  });
}
