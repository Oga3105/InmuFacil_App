import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';

// Configuration - Move to Env in production
const String kApiBaseUrl = 'http://localhost:8000/api/v1';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user, 
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Nullable to clear error
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  /// Check if user is already logged in (has valid token)
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        // Set token for Dio
        _dio.options.headers['Authorization'] = 'Bearer $token';
        
        // Validate token by fetching profile
        final user = await _fetchUserProfile();
        
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
      } else {
         state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      // If profile fetch fails, token is likely invalid/expired
      await logout();
      state = state.copyWith(isLoading: false);
    }
  }

  /// Feature: Get User Profile
  Future<User> _fetchUserProfile() async {
    try {
      final response = await _dio.get('/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  /// Login with Email and Password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _dio.post(
        '/auth/token',
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        await _storage.write(key: 'auth_token', value: token);
        
        // Update Dio default headers for future requests
        _dio.options.headers['Authorization'] = 'Bearer $token';

        // Fetch user profile
        final user = await _fetchUserProfile();

        state = state.copyWith(
          isLoading: false,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Credenciales inválidas',
        );
        return false;
      }
    } on DioException catch (e) {
      String msg = 'Error de conexión';
      if (e.response != null) {
         if (e.response?.statusCode == 401) {
            msg = 'Correo o contraseña incorrectos';
         } else {
            msg = e.response?.data['detail'] ?? 'Error en el servidor';
         }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ocurrió un error inesperado',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _dio.options.headers.remove('Authorization');
    // Start fresh state (user is null by default)
    state = AuthState(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
