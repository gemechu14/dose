import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super(message: 'No internet connection');
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed'});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;
  const ValidationFailure({required this.errors})
      : super(message: 'Validation failed');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found'});
}
