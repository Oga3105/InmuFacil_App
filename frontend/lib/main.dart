import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  // 1. OBLIGATORIO: Inicializar enlaces nativos antes de nada
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Carga segura de variables de entorno
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Environment loaded successfully.");
  } catch (e) {
    debugPrint("⚠️ WARNING: Could not load .env file. Using defaults. Error: $e");
    // No relanzamos el error para permitir que la app arranque aunque sea sin config
  }

  // 3. Arranque de la App
  runApp(
    const ProviderScope(
      child: InmuFacilApp(),
    ),
  );
}
