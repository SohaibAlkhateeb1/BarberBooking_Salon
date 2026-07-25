import 'dart:js_util' as js_util;
import 'dart:js' as js;

class WebNotificationPlatform {
  static bool _permissionGranted = false;

  static Future<bool> requestPermission() async {
    try {
      final hasApi = js.context.callMethod('eval', ["typeof Notification !== 'undefined'"]);
      if (hasApi != true) {
        print('Notification API not available in this browser');
        return false;
      }

      final currentPermission = js.context.callMethod('eval', ['Notification.permission']);
      print('Current notification permission: $currentPermission');

      if (currentPermission == 'granted') {
        _permissionGranted = true;
        print('Notification permission already granted');
        return true;
      }

      if (currentPermission == 'denied') {
        print('Notification permission was denied by user previously');
        return false;
      }

      final promise = js.context.callMethod('eval', ["Notification.requestPermission()"]);
      final result = await js_util.promiseToFuture(promise);
      print('Notification.requestPermission() result: $result');
      _permissionGranted = (result == 'granted');
      return _permissionGranted;
    } catch (e) {
      print('Web permission request error: $e');
      return false;
    }
  }

  static bool get hasPermission => _permissionGranted;

  static bool get needsInstallPrompt {
    try {
      final ua = js.context.callMethod('eval', ['navigator.userAgent']).toString().toLowerCase();
      final isIos = ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
      if (!isIos) return false;
      final standalone = js.context.callMethod('eval', ['navigator.standalone']);
      return standalone != true;
    } catch (e) {
      return false;
    }
  }

  static void showNotification({required String title, required String body}) {
    if (!_permissionGranted) {
      print('No notification permission, skip show');
      return;
    }
    try {
      final options = js_util.jsify({
        'body': body,
        'icon': '/icons/Icon-192.png',
        'badge': '/icons/Icon-192.png',
        'tag': 'barberbooking-${DateTime.now().millisecondsSinceEpoch}',
      });

      js.context['Notification'].callMethod('new', [title, options]);
      print('Browser notification shown: $title');
    } catch (e) {
      print('Browser notification error: $e');
    }
  }
}
