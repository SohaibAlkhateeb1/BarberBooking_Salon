import 'dart:async';

class AppEventBus {
  static final AppEventBus _instance = AppEventBus._();
  factory AppEventBus() => _instance;
  AppEventBus._();

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void fire(String type, {Map<String, dynamic>? data}) {
    if (_controller.isClosed) return;
    _controller.add({
      'type': type,
      ...?data,
    });
  }

  void dispose() {
    _controller.close();
  }
}
