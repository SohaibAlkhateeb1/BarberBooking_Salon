import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../errors/app_exception.dart';
import 'platform_url.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isRefreshing = false;

  static String get _baseUrl => getApiBaseUrl();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          final refreshToken = await _tokenStorage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final refreshed = await _tryRefreshToken(refreshToken);
            if (refreshed) {
              final newToken = await _tokenStorage.getToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (_) {}
            }
          }
        }
        final exception = _handleError(error);
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: exception,
          message: exception.message,
        ));
      },
    ));
  }

  Future<bool> _tryRefreshToken(String refreshToken) async {
    _isRefreshing = true;
    try {
      final response = await Dio().post(
        '$_baseUrl/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _tokenStorage.saveToken(data['token']);
        await _tokenStorage.saveRefreshToken(data['refreshToken']);
        return true;
      }
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
    return false;
  }

  Dio get dio => _dio;

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'انتهت مهلة الاتصال بالسيرفر');

      case DioExceptionType.connectionError:
        return NetworkException(message: 'لا يوجد اتصال بالإنترنت');

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      default:
        return ServerException(message: 'حدث خطأ غير متوقع');
    }
  }

  AppException _handleBadResponse(Response? response) {
    if (response == null) {
      return ServerException(message: 'لا يوجد استجابة من السيرفر');
    }

    final statusCode = response.statusCode;
    final data = response.data;

    String message = 'حدث خطأ';

    if (data is Map<String, dynamic>) {
      if (data.containsKey('message')) {
        message = data['message'].toString();
      } else if (data.containsKey('errors')) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        } else if (errors is List && errors.isNotEmpty) {
          message = errors.first.toString();
        }
      }
    }

    switch (statusCode) {
      case 400:
        return ValidationException(message: message, statusCode: statusCode);
      case 401:
        return AuthException(message: message, statusCode: statusCode);
      case 404:
        return ServerException(message: message, statusCode: statusCode);
      case 409:
        return AuthException(message: message, statusCode: statusCode);
      case 500:
        return ServerException(message: 'خطأ في السيرفر', statusCode: statusCode);
      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }
}
