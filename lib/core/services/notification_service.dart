import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class RecordedNotification {
  final int id;
  final String title;
  final String body;
  final String channelId;
  final DateTime timestamp;

  RecordedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channelId,
    required this.timestamp,
  });

  @override
  String toString() =>
      'RecordedNotification(id: $id, channel: $channelId, title: $title, body: $body)';
}

class NotificationService {
  static NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;

  @visibleForTesting
  static set instance(NotificationService customInstance) =>
      _instance = customInstance;

  FlutterLocalNotificationsPlugin? _plugin;
  bool isInitialized = false;
  bool permissionGranted = true;
  bool isHeadless = false;

  static const int maxBodyLength = 500;
  final Set<String> registeredChannels = {};
  final List<RecordedNotification> deliveredNotifications = [];
  final Map<int, RecordedNotification> activeNotificationsById = {};

  NotificationService._internal({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin;

  @visibleForTesting
  NotificationService.forTest({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin;

  bool get isHeadlessOrUnsupportedPlatform {
    if (isHeadless) return true;
    if (kIsWeb) return true;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    return false;
  }

  Future<void> initialize() async {
    registeredChannels.add('food_alerts');
    registeredChannels.add('app_events');
    if (isHeadlessOrUnsupportedPlatform) {
      isInitialized = true;
      return;
    }
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );
      _plugin ??= FlutterLocalNotificationsPlugin();
      await _plugin!.initialize(settings: initSettings);

      final androidPlugin = _plugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const foodAlertsChannel = AndroidNotificationChannel(
          'food_alerts',
          'Cảnh báo thực phẩm',
          description: 'Kênh cảnh báo dị ứng và dinh dưỡng quan trọng',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        const appEventsChannel = AndroidNotificationChannel(
          'app_events',
          'Sự kiện ứng dụng',
          description:
              'Kênh thông báo sự kiện tài khoản, quét và trạng thái ứng dụng',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
        );
        await androidPlugin.createNotificationChannel(foodAlertsChannel);
        await androidPlugin.createNotificationChannel(appEventsChannel);
        final granted = await androidPlugin.requestNotificationsPermission();
        permissionGranted = granted ?? true;
      }
      isInitialized = true;
    } catch (_) {
      isInitialized = true;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    if (!permissionGranted) return;
    final effectiveChannel = channelId ?? 'app_events';
    final effectiveBody = body.length > maxBodyLength
        ? '${body.substring(0, maxBodyLength)}...'
        : body;

    final notification = RecordedNotification(
      id: id,
      title: title,
      body: effectiveBody,
      channelId: effectiveChannel,
      timestamp: DateTime.now(),
    );
    activeNotificationsById[id] = notification;
    deliveredNotifications.add(notification);

    if (isHeadlessOrUnsupportedPlatform || _plugin == null) return;

    try {
      final isFoodAlert = effectiveChannel == 'food_alerts';
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          effectiveChannel,
          isFoodAlert ? 'Cảnh báo thực phẩm' : 'Sự kiện ứng dụng',
          channelDescription: isFoodAlert
              ? 'Kênh cảnh báo dị ứng và dinh dưỡng quan trọng'
              : 'Kênh thông báo sự kiện tài khoản, quét và trạng thái ứng dụng',
          importance:
              isFoodAlert ? Importance.max : Importance.defaultImportance,
          priority: isFoodAlert ? Priority.high : Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: isFoodAlert,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _plugin!.show(
        id: id,
        title: title,
        body: effectiveBody,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> showAllergenAlert({
    required String productName,
    required String allergenName,
  }) async {
    await showNotification(
      id: 100,
      title: 'Cảnh báo dị ứng: $productName',
      body: 'Sản phẩm có chứa $allergenName vi phạm hồ sơ ăn uống của bạn.',
      channelId: 'food_alerts',
    );
  }

  Future<void> showAggregatedAllergenAlert({
    required String productName,
    required List<String> allergens,
  }) async {
    final aggregated = allergens.join(', ');
    await showNotification(
      id: 101,
      title: 'Cảnh báo đa dị ứng: $productName',
      body: 'Sản phẩm có chứa các thành phần dị ứng: $aggregated.',
      channelId: 'food_alerts',
    );
  }

  Future<void> showNutritionAlert({
    required String productName,
    required String warningDetails,
  }) async {
    await showNotification(
      id: 102,
      title: 'Cảnh báo dinh dưỡng: $productName',
      body: 'Sản phẩm vượt ngưỡng cảnh báo: $warningDetails.',
      channelId: 'food_alerts',
    );
  }

  Future<void> showAuthNotification({
    required String title,
    required String body,
    int id = 200,
  }) async {
    await showNotification(
      id: id,
      title: title,
      body: body,
      channelId: 'app_events',
    );
  }

  Future<void> showLoginWelcome(String username) async {
    await showNotification(
      id: 200,
      title: 'Chào mừng trở lại, $username!',
      body: 'Đăng nhập thành công vào Ăn Lành.',
      channelId: 'app_events',
    );
  }

  Future<void> showRegisterWelcome(String username) async {
    await showNotification(
      id: 201,
      title: 'Chào mừng thành viên mới!',
      body: 'Tài khoản $username đã được kích hoạt thành công.',
      channelId: 'app_events',
    );
  }

  Future<void> showSafeScanNotification(String productName) async {
    await showNotification(
      id: 300,
      title: 'Sản phẩm an toàn: $productName',
      body: 'Không phát hiện vi phạm dị ứng hoặc mục tiêu dinh dưỡng.',
      channelId: 'app_events',
    );
  }

  Future<void> showScanCompletedNotification(String productName) async {
    await showNotification(
      id: 301,
      title: 'Đã quét: $productName',
      body: 'Kết quả đánh giá đã được lưu vào lịch sử.',
      channelId: 'app_events',
    );
  }

  void reset() {
    deliveredNotifications.clear();
    activeNotificationsById.clear();
    permissionGranted = true;
  }

  void resetForTest() => reset();
}
