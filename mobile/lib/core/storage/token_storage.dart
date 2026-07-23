import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _fullNameKey = 'full_name';
  static const _phoneNumberKey = 'phone_number';
  static const _roleKey = 'role';

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  Future<void> saveToken(String token) async => _write(_tokenKey, token);

  Future<String?> getToken() async => _read(_tokenKey);

  Future<void> saveRefreshToken(String refreshToken) async => _write(_refreshTokenKey, refreshToken);

  Future<String?> getRefreshToken() async => _read(_refreshTokenKey);

  Future<void> saveUserData({
    required String token,
    required String refreshToken,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    await _write(_tokenKey, token);
    await _write(_refreshTokenKey, refreshToken);
    await _write(_fullNameKey, fullName);
    await _write(_phoneNumberKey, phoneNumber);
    await _write(_roleKey, role);
  }

  Future<String?> getFullName() async => _read(_fullNameKey);

  Future<String?> getPhoneNumber() async => _read(_phoneNumberKey);

  Future<String?> getRole() async => _read(_roleKey);

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static const _pendingOtpPhoneKey = 'pending_otp_phone';

  Future<void> savePendingOtpPhone(String phone) async => _write(_pendingOtpPhoneKey, phone);

  Future<String?> getPendingOtpPhone() async => _read(_pendingOtpPhoneKey);

  Future<void> clearPendingOtpPhone() async => _delete(_pendingOtpPhoneKey);

  Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }

  Future<void> saveFullName(String fullName) async => _write(_fullNameKey, fullName);

  Future<void> savePhoneNumber(String phoneNumber) async => _write(_phoneNumberKey, phoneNumber);

  Future<String?> getCity() async => _read('city');

  Future<void> saveCity(String city) async => _write('city', city);

  Future<void> saveLocation(double latitude, double longitude) async {
    await _write('latitude', latitude.toString());
    await _write('longitude', longitude.toString());
  }

  Future<double?> getLatitude() async {
    final value = await _read('latitude');
    return value != null ? double.tryParse(value) : null;
  }

  Future<double?> getLongitude() async {
    final value = await _read('longitude');
    return value != null ? double.tryParse(value) : null;
  }
}
