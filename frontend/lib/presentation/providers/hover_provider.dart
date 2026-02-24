import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inmufacil_frontend/domain/entities/property.dart';

/// Notifier to manage hover state with a debounce timer
class HoverNotifier extends Notifier<Property?> {
  Timer? _hideTimer;

  @override
  Property? build() {
    ref.onDispose(() => _hideTimer?.cancel());
    return null;
  }

  /// Set the hovered property and CANCEL any pending hide timer
  void setHoveredProperty(Property? property) {
    _hideTimer?.cancel();
    state = property;
  }

  /// Start a timer to hide the property (e.g. when mouse leaves marker)
  /// If the mouse enters the card before timer fires, cancelHideTimer() will save it.
  void startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 300), () {
      state = null;
    });
  }

  /// Cancel the hide timer (e.g. when mouse enters the card)
  void cancelHideTimer() {
    _hideTimer?.cancel();
  }

}

/// Provider to track the property currently being hovered on the map
final hoveredPropertyProvider = NotifierProvider<HoverNotifier, Property?>(HoverNotifier.new);

/// Provider to track the property currently SELECTED (clicked) on the map
/// This state persists until another property is selected or the map background is clicked
class SelectedPropertyNotifier extends Notifier<Property?> {
  @override
  Property? build() => null;

  void select(Property? property) => state = property;
}

final selectedPropertyProvider = NotifierProvider<SelectedPropertyNotifier, Property?>(SelectedPropertyNotifier.new);
