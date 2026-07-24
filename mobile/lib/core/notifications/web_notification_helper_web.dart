import 'dart:js_util' as js_util;
import 'dart:js' as js;

class WebNotificationPlatform {
  static bool _permissionGranted = false;

  static Future<bool> requestPermission() async {
    try {
      final jsPromise = js.context['Notification'].callMethod('requestPermission', []);
      final result = await js_util.promiseToFuture(jsPromise);
      _permissionGranted = result == 'granted';
      print('Web notification permission: $_permissionGranted');
      return _permissionGranted;
    } catch (e) {
      print('Web permission request error: $e');
      return false;
    }
  }

  static bool get hasPermission => _permissionGranted;

  static void showNotification({required String title, required String body}) {
    if (!_permissionGranted) {
      print('Web notification: no permission, skipping');
      return;
    }
    try {
      final options = js_util.jsify({
        'body': body,
        'icon': '/icons/Icon-192.png',
        'badge': '/icons/Icon-192.png',
        'tag': 'barberbooking-${DateTime.now().millisecondsSinceEpoch}',
        'requireInteraction': true,
      });
      js.context['Notification'].callMethod('new', [title, options]);
      print('Web notification shown: $title');
    } catch (e) {
      print('Web notification show error: $e');
    }
  }
}
