class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({super.message = 'لا يوجد اتصال بالإنترنت', super.statusCode});
}

class ServerException extends AppException {
  ServerException({required super.message, super.statusCode});
}

class AuthException extends AppException {
  AuthException({required super.message, super.statusCode});
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException({required super.message, this.errors, super.statusCode});
}
