import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../network/api_client.dart';
import '../../features/main_shell/presentation/main_shell.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _requestPermission();
      await _initLocalNotifications();
      await _getToken();
      _setupMessageHandlers();
    } catch (e) {
      print('NotificationService init failed (non-critical): $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      print('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        print('FCM Token refreshed: $token');
        _saveTokenToBackend(token);
      });
    } catch (e) {
      print('FCM token failed (non-critical): $e');
    }
  }

  Future<void> saveTokenToBackend() async {
    if (_fcmToken != null) {
      await _saveTokenToBackend(_fcmToken!);
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _apiClient.dio.post('/api/auth/fcm-token', data: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
        'deviceName': 'Web Browser',
      });
      print('FCM Token saved to backend');
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    _navigateBasedOnData(message.data);
  }

  void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      print('Initial message: ${message.notification?.title}');
      _navigateBasedOnData(message.data);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateBasedOnData(data);
    }
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final screen = data['screen'];

    switch (type) {
      case 'booking_update':
        Get.to(() => const MainShell(initialTab: 1));
        break;
      case 'notification':
        Get.to(() => const MainShell(initialTab: 3));
        break;
      default:
        if (screen != null) {
          Get.to(() => const MainShell(initialTab: 0));
        }
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'barber_booking_channel',
      'BarberBooking Notifications',
      channelDescription: 'Notifications from BarberBooking',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }
}
