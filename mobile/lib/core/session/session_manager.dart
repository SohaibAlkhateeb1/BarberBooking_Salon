import 'dart:async';
import 'package:flutter/material.dart';
import '../storage/token_storage.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const Duration _sessionTimeout = Duration(hours: 1);
  Timer? _inactivityTimer;
  final TokenStorage _tokenStorage = TokenStorage();
  VoidCallback? _onSessionExpired;

  void initialize({required VoidCallback onSessionExpired}) {
    _onSessionExpired = onSessionExpired;
  }

  void onUserActivity() {
    _tokenStorage.updateLastActive();
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_sessionTimeout, _handleTimeout);
  }

  void _handleTimeout() {
    _inactivityTimer?.cancel();
    _onSessionExpired?.call();
  }

  Future<bool> checkSessionOnResume() async {
    final lastActive = await _tokenStorage.getLastActive();
    if (lastActive == null) return true;

    final elapsed = DateTime.now().difference(lastActive);
    if (elapsed > _sessionTimeout) {
      _inactivityTimer?.cancel();
      return false;
    }

    _resetTimer();
    return true;
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }
}
