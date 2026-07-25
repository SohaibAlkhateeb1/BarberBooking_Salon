import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:js' as js;

class WebNotificationPlatform {
  static bool _permissionGranted = false;

  static Future<bool> requestPermission() async {
    try {
      final hasApi = js.context.callMethod('eval', ["typeof Notification !== 'undefined'"]);
      if (hasApi != true) {
        print('Notification API not available');
        return false;
      }

      final currentPermission = js.context.callMethod('eval', ['Notification.permission']);
      print('Current permission before request: $currentPermission');

      if (currentPermission == 'granted') {
        _permissionGranted = true;
        return true;
      }

      if (currentPermission == 'denied') {
        print('Permission was previously denied');
        return false;
      }

      js.context.callMethod('eval', ['Notification.requestPermission()']);

      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final perm = js.context.callMethod('eval', ['Notification.permission']);
        print('Permission check $i: $perm');
        if (perm == 'granted') {
          _permissionGranted = true;
          print('Permission granted after ${i * 500}ms');
          return true;
        }
        if (perm == 'denied') {
          print('Permission denied after ${i * 500}ms');
          return false;
        }
      }

      print('Permission timeout, still default');
      return false;
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
    if (!_permissionGranted) return;
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
