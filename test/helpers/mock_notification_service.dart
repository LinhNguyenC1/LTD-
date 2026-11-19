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
  String toString() {
    return 'RecordedNotification(id: $id, channel: $channelId, title: $title, body: $body)';
  }
}

class MockNotificationService {
  bool isInitialized = false;
  bool permissionGranted = true;
  bool isHeadless = true;

  final Set<String> registeredChannels = {};
  final List<RecordedNotification> deliveredNotifications = [];
  final Map<int, RecordedNotification> activeNotificationsById = {};

  static const int maxBodyLength = 500;

  Future<void> initialize() async {
    registeredChannels.add('food_alerts');
    registeredChannels.add('app_events');
    isInitialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
  }) async {
    if (!permissionGranted) {
      return;
    }

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
}
