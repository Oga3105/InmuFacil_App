import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;

  AuthState({this.user, this.isLoading = false});

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  // Placeholder for login/logout logic
  void mockLogin() {
    state = AuthState(user: User(id: '1', email: 'user@example.com', name: 'Test User'));
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
