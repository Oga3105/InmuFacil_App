import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  
  const Failure(this.message);
  final String message;
  
  @override
  List<Object> get props => [message];
}

/// Server-side failures (5xx errors)
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Client-side failures (4xx errors)
class ClientFailure extends Failure {
  const ClientFailure([super.message = 'Client error occurred']);
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

/// Not found failures (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

/// Service unavailable failures (503 - e.g. database down)
/// i18n key: errors.service_unavailable_detail
class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure([
    super.message = 'El servicio de datos no está disponible en este momento. Inténtalo de nuevo en unos minutos.',
  ]);
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}
