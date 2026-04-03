// Generado a partir de la configuración del proyecto Firebase "inmufacil".
// Proyecto: inmufacil | App Web: 1:849495548519:web:474e1c80818fc8ca1deac2

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma. '
          'Ejecuta "flutterfire configure" para generar la config nativa.',
        );
      default:
        throw UnsupportedError(
          'Plataforma desconocida. DefaultFirebaseOptions solo soporta web por ahora.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhiczYPaQ0J6jgdQcmbJ1ot1q6rTT51WM',
    appId: '1:849495548519:web:474e1c80818fc8ca1deac2',
    messagingSenderId: '849495548519',
    projectId: 'inmufacil',
    authDomain: 'inmufacil.firebaseapp.com',
    storageBucket: 'inmufacil.firebasestorage.app',
    // Web OAuth Client ID (Firebase Console → Authentication → Google → Web SDK config)
    clientId: '849495548519-58blbnuu0rsgan6bb8tn6hdfu9dkk916.apps.googleusercontent.com',
  );

}