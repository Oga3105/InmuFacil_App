import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/core/errors/failures.dart';
import 'package:inmufacil_frontend/core/constants/api_constants.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';
import 'package:inmufacil_frontend/domain/repositories/property_repository.dart';
import 'package:inmufacil_frontend/data/models/property_model.dart';
import 'package:inmufacil_frontend/data/datasources/remote/api_client.dart';

/// Implementation of PropertyRepository using API
class PropertyRepositoryImpl implements PropertyRepository {
  
  PropertyRepositoryImpl(this._apiClient);
  final ApiClient _apiClient;
  
  @override
  Future<Either<Failure, List<Property>>> getProperties({
    PropertyType? type,
    double? minPrice,
    double? maxPrice,
    LatLng? center,
    double? radiusKm,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};
      
      if (type != null && type != PropertyType.all) {
        queryParams['type'] = _propertyTypeToString(type);
      }
      
      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
      }
      
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
      }
      
      if (center != null) {
        queryParams['lat'] = center.latitude;
        queryParams['lng'] = center.longitude;
      }
      
      if (radiusKm != null) {
        queryParams['radius'] = radiusKm;
      }
      
      // Make API request
      final response = await _apiClient.client.get(
        ApiConstants.propertyList,
        queryParameters: queryParams,
      );
      
      // Parse response
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        
        // Convert to domain entities
        final properties = data
            .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
            .map((model) => model.toEntity())
            .toList();
        
        return Right(properties);
      } else if (response.statusCode == 404) {
        // No properties found - return empty list (estado cero)
        return const Right([]);
      } else {
        return const Left(ServerFailure('Error al cargar propiedades'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, Property>> getPropertyById(String id) async {
    try {
      final response = await _apiClient.client.get(
        ApiConstants.propertyDetail(int.parse(id)),
      );
      
      if (response.statusCode == 200) {
        final propertyModel = PropertyModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Right(propertyModel.toEntity());
      } else if (response.statusCode == 404) {
        return const Left(NotFoundFailure('Propiedad no encontrada'));
      } else {
        return const Left(ServerFailure('Error al cargar propiedad'));
      }
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
  
  /// Handle Dio errors and convert to Failures
  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Tiempo de espera agotado');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return const AuthFailure();
        } else if (statusCode == 404) {
          return const NotFoundFailure();
        } else if (statusCode == 503) {
          // Database / service unavailable (e.g. Docker Desktop off)
          return const ServiceUnavailableFailure();
        } else if (statusCode != null && statusCode >= 500) {
          return const ServerFailure();
        } else {
          return ValidationFailure(
            error.response?.data?['message'] ?? 'Error de validación',
          );
        }
      
      case DioExceptionType.connectionError:
        return const ServiceUnavailableFailure(
          'No se puede conectar con el servidor. Comprueba que el servicio está activo e inténtalo de nuevo.',
        );

      case DioExceptionType.cancel:
        return const ServerFailure('Petición cancelada');

      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') ?? false) {
          return const ServiceUnavailableFailure(
            'No se puede conectar con el servidor. Comprueba que el servicio está activo e inténtalo de nuevo.',
          );
        }
        return const ServiceUnavailableFailure(
          'No se puede conectar con el servidor. Comprueba que el servicio está activo e inténtalo de nuevo.',
        );
    }
  }
  
  /// Convert PropertyType to API string
  String _propertyTypeToString(PropertyType type) {
    return type.backendValue;
  }
}
