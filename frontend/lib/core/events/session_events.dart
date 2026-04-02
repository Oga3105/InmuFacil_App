import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Broadcast stream — fires whenever any Dio interceptor receives a 401
// ---------------------------------------------------------------------------

final _controller = StreamController<void>.broadcast();

/// Raw stream that any Dio [AuthInterceptor] can write to.
Stream<void> get sessionExpiredStream => _controller.stream;

/// Called by [AuthInterceptor] when a 401 response is detected AND the user
/// had an active token (i.e., the session truly expired, not a login failure).
void notifySessionExpired() {
  if (!_controller.isClosed) {
    _controller.add(null);
  }
}

// ---------------------------------------------------------------------------
// Riverpod StreamProvider — consumed by the app-level listener in app.dart
// ---------------------------------------------------------------------------

final sessionExpiredProvider = StreamProvider<void>(
  (ref) => sessionExpiredStream,
);
