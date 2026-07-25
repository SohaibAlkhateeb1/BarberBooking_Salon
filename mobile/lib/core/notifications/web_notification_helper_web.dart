import 'dart:js_util' as js_util;
import 'dart:js' as js;

class WebNotificationPlatform {
  static bool _permissionGranted = false;

  static Future<bool> requestPermission() async {
    try {
      final isIosBrowser = _isIos() && !_isStandalone();

      if (isIosBrowser) {
        print('iOS browser detected - notifications require Add to Home Screen');
        return false;
      }

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
      if (standalone != null) return standalone.toString() == 'true';
      final displayMode = js.context['matchMedia']
          ?.callMethod('matches', ['(display-mode: standalone)']);
      if (displayMode != null) return displayMode.toString() == 'true';
      return false;
    } catch (e) {
      return false;
    }
  }

  static void showNotification({required String title, required String body}) {
    if (_isIos() && !_isStandalone()) {
      print('iOS browser: cannot show notification, needs Add to Home Screen');
      return;
    }
    if (!_permissionGranted) return;
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
