import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthResponse {
  final String token;
  final DateTime expiration;
  final String refreshToken;
  final DateTime refreshTokenExpiration;
  final String fullName;
  final String phoneNumber;
  final String role;

  AuthResponse({
    required this.token,
    required this.expiration,
    required this.refreshToken,
    required this.refreshTokenExpiration,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
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

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage = TokenStorage();

  AuthService(this._apiClient);

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    bool acceptTerms = true,
    String? profileImageUrl,
  }) async {
    await _apiClient.dio.post(
      '/api/auth/register',
      data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'password': password,
        'acceptTerms': acceptTerms,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      },
    );
  }

  Future<AuthResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/auth/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    final authResponse = AuthResponse.fromJson(response.data);

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
          '/api/auth/logout',
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
