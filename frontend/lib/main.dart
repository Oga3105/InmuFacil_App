import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';

void main() async {
  // 1. OBLIGATORIO: Inicializar enlaces nativos antes de nada
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Path-based URL strategy: URLs limpias sin '#'
  //    localhost:8001/property/123  en vez de  localhost:8001/#/property/123
  //    F5 en cualquier ruta funciona correctamente con flutter run y Nginx/Cloudflare
  usePathUrlStrategy();

  // 2. Carga segura de variables de entorno
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment loaded successfully.');
  } catch (e) {
    debugPrint('⚠️ WARNING: Could not load .env file. Using defaults. Error: $e');
    // No relanzamos el error para permitir que la app arranque aunque sea sin config
  }

  // 3. Arranque de la App
  runApp(
    const ProviderScope(
      child: InmuFacilApp(),
    ),
  );
}
