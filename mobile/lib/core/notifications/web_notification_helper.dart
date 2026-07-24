import 'web_notification_helper_stub.dart'
    if (dart.library.js_interop) 'web_notification_helper_web.dart';

abstract class WebNotificationHelper {
  static Future<bool> requestPermission() => WebNotificationPlatform.requestPermission();
  static void showNotification({required String title, required String body}) => WebNotificationPlatform.showNotification(title: title, body: body);
  static bool get hasPermission => WebNotificationPlatform.hasPermission;
}
