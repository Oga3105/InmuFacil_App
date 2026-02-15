import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';

/// Provider to track the property currently being hovered on the map
/// Used to display the Preview Card on the left panel
final hoveredPropertyProvider = StateProvider<Property?>((ref) => null);

/// Provider to track the property currently SELECTED (clicked) on the map
/// This state persists until another property is selected or the map background is clicked
final selectedPropertyProvider = StateProvider<Property?>((ref) => null);
