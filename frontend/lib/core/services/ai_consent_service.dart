import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env_config.dart';
import '../network/auth_interceptor.dart';
import '../../presentation/providers/auth_provider.dart';

/// Configuration object describing a single AI action that requires consent.
class AiConsentConfig {
  const AiConsentConfig({
    required this.actionType,
    required this.actionLabel,
    required this.dataCategories,
    required this.purpose,
    required this.aiProvider,
    this.propertyId,
    this.consentTextVersion = 'v1.0',
  });

  final String actionType;
  final String actionLabel;
  final List<String> dataCategories;
  final String purpose;
  final String aiProvider;
  final String? propertyId;
  final String consentTextVersion;

  // ── Pre-defined configs ────────────────────────────────────────────────────

  static const propertyDescription = AiConsentConfig(
    actionType: 'property_description',
    actionLabel: 'Generacion de descripcion de inmueble con IA',
    dataCategories: [
      'Datos del inmueble (tipo, precio, superficie, habitaciones, ubicacion)',
      'Imagenes del inmueble',
      'Caracteristicas y equipamiento (ascensor, garaje, piscina, etc.)',
    ],
    purpose:
        'Generar automaticamente una descripcion comercial del inmueble para su publicacion en la plataforma.',
    aiProvider: 'Google Gemini (Google LLC)',
  );

  static const aiComfortReport = AiConsentConfig(
    actionType: 'ai_comfort_report',
    actionLabel: 'Generacion de informe de confort ambiental con IA',
    dataCategories: [
      'Coordenadas GPS del inmueble (latitud y longitud)',
      'Codigo postal y municipio',
      'Tipo de inmueble',
    ],
    purpose:
        'Analizar datos ambientales y de entorno (ruido, calidad del aire, zonas verdes, etc.) '
        'de la ubicacion del inmueble para generar un informe de confort destinado a compradores.',
    aiProvider: 'Google Gemini (Google LLC)',
  );

  static const kycVerification = AiConsentConfig(
    actionType: 'kyc_identity_verification',
    actionLabel: 'Verificacion de identidad con IA',
    dataCategories: [
      'Imagen del documento de identidad (anverso y reverso)',
      'Fotografia facial (selfie)',
      'Numero de documento de identidad',
    ],
    purpose:
        'Verificar la autenticidad del documento de identidad y la coincidencia con la fotografia del titular, para garantizar la seguridad de las transacciones P2P.',
    aiProvider: 'Google Gemini (Google LLC)',
  );
}

/// Resultado de registrar el consentimiento en backend.
class AiConsentRecord {
  const AiConsentRecord({required this.id, required this.consentedAt});
  final int id;
  final DateTime consentedAt;
}

/// Singleton que gestiona el registro de consentimientos IA en el backend.
class AiConsentService {
  AiConsentService._();
  static final instance = AiConsentService._();

  final _storage = const FlutterSecureStorage();
  late final _dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(AuthInterceptor());

  Future<String?> _token() => _storage.read(key: 'auth_token');

  /// Registra el consentimiento en la base de datos.
  /// Lanza [AiConsentException] si el registro falla.
  /// El llamante NO debe proceder con la accion si este metodo lanza.
  Future<AiConsentRecord> record(AiConsentConfig config) async {
    final token = await _token();
    if (token == null) throw AiConsentException('Usuario no autenticado.');

    try {
      final response = await _dio.post(
        '/ai-consent',
        data: {
          'action_type': config.actionType,
          'action_label': config.actionLabel,
          'data_categories': config.dataCategories,
          'purpose': config.purpose,
          'ai_provider': config.aiProvider,
          'consent_text_version': config.consentTextVersion,
          if (config.propertyId != null) 'property_id': config.propertyId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return AiConsentRecord(
        id: response.data['id'] as int,
        consentedAt: DateTime.parse(response.data['consented_at'] as String),
      );
    } on DioException catch (e) {
      throw AiConsentException(
        e.response?.data?['detail'] ?? 'Error al registrar el consentimiento.',
      );
    }
  }
}

class AiConsentException implements Exception {
  const AiConsentException(this.message);
  final String message;

  @override
  String toString() => 'AiConsentException: $message';
}
