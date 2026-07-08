class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'NetworkException: No internet connection';
}

class AuthException implements Exception {
  final String message;
  const AuthException({this.message = 'Unauthorized'});

  @override
  String toString() => 'AuthException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final Map<String, List<String>> errors;
  const ValidationException({required this.errors});

  @override
  String toString() => 'ValidationException: $errors';
}
