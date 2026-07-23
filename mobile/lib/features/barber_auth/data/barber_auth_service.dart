import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class BarberAuthResponse {
  final String token;
  final DateTime expiration;
  final String refreshToken;
  final DateTime refreshTokenExpiration;
  final String fullName;
  final String phoneNumber;
  final String role;

  BarberAuthResponse({
    required this.token,
    required this.expiration,
    required this.refreshToken,
    required this.refreshTokenExpiration,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });

  factory BarberAuthResponse.fromJson(Map<String, dynamic> json) {
    return BarberAuthResponse(
      token: json['token'] ?? '',
      expiration: DateTime.parse(json['expiration']),
      refreshToken: json['refreshToken'] ?? '',
      refreshTokenExpiration: DateTime.parse(json['refreshTokenExpiration']),
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class BarberAuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage = TokenStorage();

  BarberAuthService(this._apiClient);

  Future<BarberAuthResponse> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String shopName,
    String? shopDescription,
    String? profileImageUrl,
    String? shopLogoUrl,
    required String city,
    required String address,
    double? latitude,
    double? longitude,
    required String subscriptionPlan,
    required bool isYearly,
    required List<Map<String, dynamic>> services,
    required List<Map<String, dynamic>> workingHours,
    bool acceptTerms = true,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/barber/register',
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'password': password,
        'shopName': shopName,
        'shopDescription': shopDescription,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (shopLogoUrl != null) 'shopLogoUrl': shopLogoUrl,
        'city': city,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'subscriptionPlan': subscriptionPlan,
        'isYearly': isYearly,
        'services': services,
        'workingHours': workingHours,
        'acceptTerms': acceptTerms,
      },
    );

    final authResponse = BarberAuthResponse.fromJson(response.data);

    await _tokenStorage.saveUserData(
      token: authResponse.token,
      refreshToken: authResponse.refreshToken,
      fullName: authResponse.fullName,
      phoneNumber: authResponse.phoneNumber,
      role: authResponse.role,
    );

    return authResponse;
  }

  Future<BarberAuthResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/barber/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    final authResponse = BarberAuthResponse.fromJson(response.data);

    await _tokenStorage.saveUserData(
      token: authResponse.token,
      refreshToken: authResponse.refreshToken,
      fullName: authResponse.fullName,
      phoneNumber: authResponse.phoneNumber,
      role: authResponse.role,
    );

    return authResponse;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.dio.post(
          '/api/barber/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  Future<void> sendOtp({required String phoneNumber, String? purpose}) async {
    await _apiClient.dio.post(
      '/api/auth/send-otp',
      data: {
        'phoneNumber': phoneNumber,
        if (purpose != null) 'purpose': purpose,
      },
    );
  }

  Future<bool> verifyOtp({required String phoneNumber, required String code}) async {
    final response = await _apiClient.dio.post(
      '/api/auth/verify-otp',
      data: {
        'phoneNumber': phoneNumber,
        'code': code,
      },
    );
    return response.data['verified'] ?? false;
  }

  Future<void> forgotPassword({required String phoneNumber}) async {
    await _apiClient.dio.post(
      '/api/auth/forgot-password',
      data: {'phoneNumber': phoneNumber},
    );
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) async {
    await _apiClient.dio.post(
      '/api/auth/reset-password',
      data: {
        'phoneNumber': phoneNumber,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }
}
