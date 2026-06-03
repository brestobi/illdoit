/// Custom exception classes for error handling
abstract class AppException implements Exception {

  AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class AuthenticationException extends AppException {
  AuthenticationException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class ServerException extends AppException {
  ServerException(super.message);
}

class LocalStorageException extends AppException {
  LocalStorageException(super.message);
}

class InsufficientFundsException extends AppException {
  InsufficientFundsException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}
