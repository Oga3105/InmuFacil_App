import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/user.dart';

// Configuration - Move to Env in production
const String kApiBaseUrl = 'http://localhost:8000/api/v1';

class AuthState {

  AuthState({
    this.user, 
    this.isLoading = false,
    this.errorMessage,
  });
  final User? user;
  final bool isLoading;
  final String? errorMessage;

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

class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),);

  @override
  AuthState build() {
    Future.microtask(checkAuthStatus);
    return AuthState();
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

  /// Register new user
  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'user_type': 'particular', // Default for now
        },
      );

      if (response.statusCode == 201) {
        // Registration successful
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error en el registro',
        );
        return false;
      }
    } on DioException catch (e) {
      String msg = 'Error de conexión';
      if (e.response != null) {
         msg = e.response?.data['detail'] ?? 'Error en el servidor';
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

  /// Update profile (name, phone)
  Future<Map<String, dynamic>> updateProfile({String? fullName, String? phone}) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;

      final response = await _dio.put('/users/me', data: body);
      final updatedUser = User.fromJson(response.data);
      state = state.copyWith(user: updatedUser);
      return {'success': true};
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al actualizar perfil';
      return {'success': false, 'error': msg is String ? msg : 'Error al actualizar perfil'};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado'};
    }
  }

  /// Change password (authenticated)
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return {'success': true};
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al cambiar contraseña';
      return {'success': false, 'error': msg is String ? msg : 'Error al cambiar contraseña'};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado'};
    }
  }

  /// Upload or replace profile photo
  Future<Map<String, dynamic>> uploadProfilePhoto(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Detect MIME from extension (more reliable on web than XFile.mimeType)
      final ext = imageFile.name.split('.').last.toLowerCase();
      const extToMime = {
        'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
        'png': 'image/png', 'webp': 'image/webp', 'gif': 'image/gif',
      };
      final mimeType = extToMime[ext] ?? imageFile.mimeType ?? 'image/jpeg';
      final parts = mimeType.split('/');
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
          contentType: DioMediaType(parts[0], parts.length > 1 ? parts[1] : 'jpeg'),
        ),
      });

      final response = await _dio.post('/users/me/photo', data: formData);
      final updatedUser = User.fromJson(response.data);
      state = state.copyWith(user: updatedUser);
      return {'success': true, 'url': updatedUser.profilePhotoUrl};
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al subir la foto';
      return {'success': false, 'error': msg is String ? msg : 'Error al subir la foto'};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado'};
    }
  }

  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      await _dio.delete('/users/me/photo');
      final updatedUser = state.user?.copyWith(clearProfilePhoto: true);
      if (updatedUser != null) {
        state = state.copyWith(user: updatedUser);
      }
      return {'success': true};
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al eliminar la foto';
      return {'success': false, 'error': msg is String ? msg : 'Error al eliminar la foto'};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado'};
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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
