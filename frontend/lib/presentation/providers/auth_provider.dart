import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/config/env_config.dart';
import '../../domain/entities/user.dart';
import 'my_properties_provider.dart';
import 'offers_provider.dart';
import 'chat_provider.dart';

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
  // clientId OBLIGATORIO en Flutter Web (google_sign_in v6+).
  // Valor leido desde .env → GOOGLE_WEB_CLIENT_ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: EnvConfig.googleWebClientId,
    scopes: ['email', 'profile'],
  );
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
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
      final user = User.fromJson(response.data);
      final photoUrl = user.profilePhotoUrl;
      if (photoUrl != null && photoUrl.startsWith('/')) {
        final origin = Uri.parse(EnvConfig.apiBaseUrl).origin;
        return user.copyWith(profilePhotoUrl: '$origin$photoUrl');
      }
      return user;
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  /// Refresh the current user profile from the API (e.g. after KYC submission).
  Future<void> refreshUser() async {
    try {
      final user = await _fetchUserProfile();
      state = state.copyWith(user: user);
    } catch (_) {}
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
        // Invalidate user-scoped providers so they reload with the new user's data
        ref.invalidate(myPropertiesProvider);
        ref.invalidate(sentOffersProvider);
        ref.invalidate(receivedOffersProvider);
        ref.invalidate(chatListProvider);
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
      },);
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

      await _dio.post('/users/me/photo', data: formData);
      final updatedUser = await _fetchUserProfile();
      state = state.copyWith(user: updatedUser);
      return {'success': true, 'url': updatedUser.profilePhotoUrl};
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al subir la foto';
      return {'success': false, 'error': msg is String ? msg : 'Error al subir la foto'};
    } catch (e) {
      return {'success': false, 'error': 'Error inesperado'};
    }
  }

  /// Permanent account deletion (GDPR right to erasure).
  /// Called when user declines GDPR consent on onboarding.
  /// Deletes the account from the backend, then clears local session.
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/users/me');
    } catch (_) {
      // If the request fails (network error, account already gone), proceed
      // with local cleanup anyway so the user is never stuck.
    }
    await logout();
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

  /// Google Sign-In — retorna is_new_user o lanza excepcion
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Paso 1: Flujo nativo de Google
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        // Usuario cancelo el dialogo
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Paso 2: Obtener Firebase ID token (verificado server-side)
      final googleAuth = await googleAccount.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final firebaseUserCredential =
          await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken =
          await firebaseUserCredential.user!.getIdToken();

      // Paso 3: Enviar Firebase ID token al backend
      final response = await _dio.post(
        '/auth/google',
        data: {'firebase_id_token': firebaseIdToken},
      );

      final token = response.data['access_token'] as String;
      final isNewUser = response.data['is_new_user'] as bool? ?? false;

      // Paso 4: Persistir JWT propio y cargar perfil
      await _storage.write(key: 'auth_token', value: token);
      _dio.options.headers['Authorization'] = 'Bearer $token';

      if (!isNewUser) {
        final user = await _fetchUserProfile();
        state = state.copyWith(isLoading: false, user: user);
        ref.invalidate(myPropertiesProvider);
        ref.invalidate(sentOffersProvider);
        ref.invalidate(receivedOffersProvider);
        ref.invalidate(chatListProvider);
      } else {
        // Usuario nuevo: no cargamos perfil aun, el onboarding lo completara
        state = state.copyWith(isLoading: false);
      }

      return isNewUser;
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Error al autenticar con Google';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg is String ? msg : 'Error al autenticar con Google',
      );
      return false;
    } catch (e, st) {
      // ignore: avoid_print
      print('[GoogleSignIn] Error inesperado: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado con Google Sign-In: $e',
      );
      return false;
    }
  }

  /// Logout (user-initiated — also signs out of Google).
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _dio.options.headers.remove('Authorization');
    await _googleSignIn.signOut().catchError((_) => null);
    ref.invalidate(myPropertiesProvider);
    ref.invalidate(sentOffersProvider);
    ref.invalidate(receivedOffersProvider);
    ref.invalidate(chatListProvider);
    state = AuthState(isLoading: false);
  }

  /// Force-logout triggered by a 401 session-expiry event.
  ///
  /// The [AuthInterceptor] has already deleted the token from secure storage
  /// before calling this. We only need to clear the in-memory state and
  /// invalidate user-scoped providers. Google sign-out is attempted silently
  /// but not awaited so it never blocks the UI redirect.
  void forceLogout() {
    _dio.options.headers.remove('Authorization');
    ref.invalidate(myPropertiesProvider);
    ref.invalidate(sentOffersProvider);
    ref.invalidate(receivedOffersProvider);
    ref.invalidate(chatListProvider);
    state = AuthState(isLoading: false);
    _googleSignIn.signOut().catchError((_) => null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
