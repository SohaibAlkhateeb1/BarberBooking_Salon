import 'dart:js_util' as js_util;
import 'dart:js' as js;

class WebNotificationPlatform {
  static bool _permissionGranted = false;

  static Future<bool> requestPermission() async {
    try {
      final isIos = _isIos();
      final isStandalone = _isStandalone();

      print('WebNotification: isIos=$isIos, isStandalone=$isStandalone');

      if (isIos && !isStandalone) {
        print('iOS browser (not PWA) - notifications require Add to Home Screen');
        return false;
      }

      final permission = await _getNotificationPermission();
      print('Notification.permission before request: $permission');

      if (permission == 'granted') {
        _permissionGranted = true;
        return true;
      }

      if (permission == 'denied') {
        print('Notification permission already denied by user');
        return false;
      }

      final jsPromise = js.context['Notification'].callMethod('requestPermission', []);
      final result = await js_util.promiseToFuture(jsPromise);
      print('Notification.requestPermission result: $result');
      _permissionGranted = result == 'granted';
      return _permissionGranted;
    } catch (e) {
      print('Web permission request error: $e');
      return false;
    }
  }

  static String? _getNotificationPermission() {
    try {
      final perm = js.context['Notification']['permission'];
      return perm?.toString();
    } catch (e) {
      return null;
    }
  }

  static bool get hasPermission => _permissionGranted;

  static bool get needsInstallPrompt => _isIos() && !_isStandalone();

  static bool _isIos() {
    try {
      final ua = js.context['navigator']['userAgent'].toString().toLowerCase();
      return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
    } catch (e) {
      return false;
    }
  }

  static bool _isStandalone() {
    try {
      final standalone = js.context['navigator']['standalone'];
      if (standalone != null && standalone.toString() == 'true') {
        print('navigator.standalone = true');
        return true;
      }
    } catch (e) {
      print('navigator.standalone check failed: $e');
    }

    try {
      final displayMode = js.context.callMethod(
        'eval',
        ["window.matchMedia('(display-mode: standalone)').matches"],
      );
      if (displayMode != null && displayMode.toString() == 'true') {
        print('display-mode: standalone = true');
        return true;
      }
    } catch (e) {
      print('display-mode check failed: $e');
    }

    try {
      final displayMode2 = js.context.callMethod(
        'eval',
        ["window.matchMedia('(display-mode: fullscreen)').matches"],
      );
      if (displayMode2 != null && displayMode2.toString() == 'true') {
        print('display-mode: fullscreen = true');
        return true;
      }
    } catch (e) {}

    return false;
  }

  static void showNotification({required String title, required String body}) {
    if (_isIos() && !_isStandalone()) {
      print('iOS browser: cannot show notification, needs Add to Home Screen');
      return;
    }
    if (!_permissionGranted) {
      print('No notification permission, skipping');
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
