import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import 'package:inmufacil_frontend/core/errors/failures.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';
import 'package:inmufacil_frontend/domain/entities/property_type.dart';

/// Repository interface for property operations
abstract class PropertyRepository {
  /// Get list of properties with optional filters
  /// 
  /// Returns [Right(List<Property>)] on success (empty list if no results)
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, List<Property>>> getProperties({
    PropertyType? type,
    double? minPrice,
    double? maxPrice,
    LatLng? center,
    double? radiusKm,
  });
  
  /// Get single property by ID
  /// 
  /// Returns [Right(Property)] on success
  /// Returns [Left(NotFoundFailure)] if property doesn't exist
  /// Returns [Left(Failure)] on other errors
  Future<Either<Failure, Property>> getPropertyById(String id);
}
