import 'dart:js' as js;

class PlatformCheck {
  static bool isIosBrowser() {
    try {
      final ua = js.context['navigator']['userAgent'].toString().toLowerCase();
      return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
    } catch (e) {
      return false;
    }
  }

  static bool isStandalone() {
    try {
      final standalone = js.context['navigator']['standalone'];
      if (standalone != null && standalone.toString() == 'true') return true;
      final mq = js.context['matchMedia']?.callMethod(
        'call',
        [js.context['window'], '(display-mode: standalone)'],
      );
      if (mq != null && mq['matches'] == true) return true;
      return false;
    } catch (e) {
      return false;
    }
  }
}
