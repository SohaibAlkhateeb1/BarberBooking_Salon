class WebNotificationPlatform {
  static Future<bool> requestPermission() async => false;
  static void showNotification({required String title, required String body}) {}
  static bool get hasPermission => false;
}
