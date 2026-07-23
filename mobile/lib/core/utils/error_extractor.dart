import '../errors/app_exception.dart';

String extractErrorMessage(Object e) {
  if (e is AppException) return e.message;
  return e.toString();
}
