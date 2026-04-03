import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  // 1. OBLIGATORIO: Inicializar enlaces nativos antes de nada
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Path-based URL strategy: URLs limpias sin '#'
  //    localhost:8001/property/123  en vez de  localhost:8001/#/property/123
  //    F5 en cualquier ruta funciona correctamente con flutter run y Nginx/Cloudflare
  usePathUrlStrategy();

  // 3. Inicializar Firebase (Google Sign-In, Auth)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Inicializar easy_localization
  await EasyLocalization.ensureInitialized();

  // 5. Carga segura de variables de entorno
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('Environment loaded successfully.');
  } catch (e) {
    debugPrint('WARNING: Could not load .env file. Using defaults. Error: $e');
    // No relanzamos el error para permitir que la app arranque aunque sea sin config
  }

  // 6. Arranque de la App envuelta en EasyLocalization
  //    saveLocale: true persiste automaticamente el idioma elegido entre sesiones
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('en', 'CA'),
        Locale('fr', 'FR'),
        Locale('fr', 'CA'),
        Locale('ca', 'ES'),
        Locale('eu', 'ES'),
        Locale('gl', 'ES'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('es', 'ES'),
      startLocale: const Locale('es', 'ES'),
      saveLocale: true,
      child: const ProviderScope(
        child: InmuFacilApp(),
      ),
    ),
  );
}
