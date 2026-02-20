import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Server-side failures (5xx errors)
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) 
      : super(message);
}

/// Client-side failures (4xx errors)
class ClientFailure extends Failure {
  const ClientFailure([String message = 'Client error occurred']) 
      : super(message);
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) 
      : super(message);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) 
      : super(message);
}

/// Not found failures (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found']) 
      : super(message);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation failed']) 
      : super(message);
}

/// Service unavailable failures (503 - e.g. database down)
/// i18n key: errors.service_unavailable_detail
class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure([
    String message = 'El servicio de datos no está disponible en este momento. Inténtalo de nuevo en unos minutos.'
  ]) : super(message);
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) 
      : super(message);
}
