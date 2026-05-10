/// Custom exception classes for error handling
abstract class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

class AuthenticationException extends AppException {
  AuthenticationException(String message) : super(message);
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message);
}

class ServerException extends AppException {
  ServerException(String message) : super(message);
}

class LocalStorageException extends AppException {
  LocalStorageException(String message) : super(message);
}

class InsufficientFundsException extends AppException {
  InsufficientFundsException(String message) : super(message);
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message);
}
