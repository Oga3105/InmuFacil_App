# ADR 016: Google OAuth — Autenticacion Social sin Firebase

**Estado:** Aceptado
**Fecha:** 2026-03-22
**Autores:** @Shield, @Architect, @FrontendProxy

---

## Contexto

InmuFacil necesitaba ofrecer registro y login mediante Google (Gmail) para reducir la friccion en el proceso de onboarding. Los usuarios no quieren crear una contrasena nueva para una plataforma que no conocen.

La implementacion original intentaba usar Firebase Authentication como intermediario, lo cual generaba varios problemas:
- Dependencia de Firebase SDK en el cliente Flutter (peso, complejidad)
- Error "google.accounts.id.initialize() called multiple times" en web por instancias multiples de GoogleSignIn
- Necesidad de `firebase_admin` en el backend para verificar tokens
- Complejidad de configuracion (google-services.json, GoogleService-Info.plist)

---

## Decision

Implementar Google OAuth usando **google_sign_in package directamente**, sin Firebase como intermediario, y verificar el ID token en el backend via la **API tokeninfo de Google** (endpoint publico de Google, sin SDK adicional).

### Flujo tecnico

```
[Flutter cliente]
    1. google_sign_in.signIn() → popup/sheet de seleccion de cuenta
    2. googleAccount.authentication → obtiene idToken (Google ID token JWT)
    3. POST /auth/google { google_id_token: idToken }

[FastAPI backend]
    4. GET https://oauth2.googleapis.com/tokeninfo?id_token=<token>
    5. Valida: status 200, sin "error", aud == GOOGLE_WEB_CLIENT_ID
    6. Extrae: sub (google_id), email, name, email_verified
    7. Busca usuario por google_id → si no existe, busca por email
    8. Caso A: usuario nuevo → crea cuenta → is_new_user: true
    9. Caso B: cuenta local existente → vincula google_id → is_new_user: false
    10. Caso C: cuenta Google ya vinculada → login directo → is_new_user: false
    11. Genera JWT propio de InmuFacil → devuelve { access_token, is_new_user }

[Flutter cliente]
    12. is_new_user: true → ruta /onboarding/consent (GDPR) → /onboarding/user-type
    13. is_new_user: false → ruta / (home)
```

### Configuracion de GoogleSignIn (singleton)

Para evitar el error "initialize() called multiple times" en Flutter Web, se usa un patron singleton para la instancia de GoogleSignIn:

```dart
// En AuthNotifier
GoogleSignIn? _cachedGoogleSignIn;
GoogleSignIn get _googleSignIn {
  _cachedGoogleSignIn ??= GoogleSignIn(
    clientId: webClientId,        // Para Flutter Web (OAuth popup)
    serverClientId: webClientId,  // Para Android/iOS (obtener idToken verificable)
    scopes: ['email', 'profile', 'openid'],
  );
  return _cachedGoogleSignIn!;
}
```

Tanto `clientId` como `serverClientId` usan el mismo **Web Client ID** de Google Cloud Console.

---

## Consecuencias

### Positivas
- **Sin Firebase:** Elimina 4MB+ de dependencias, simplifica configuracion
- **Sin firebase-admin en backend:** No hay credenciales de servicio que gestionar
- **Verificacion server-side segura:** Google tokeninfo valida la firma criptografica del token
- **Desacoplado:** El backend no depende del SDK de ningun proveedor OAuth externo
- **Compatible web+movil:** La misma logica funciona en Flutter Web y futuro APK Android

### Negativas / Limitaciones
- **Rate limits:** La API tokeninfo tiene limites de llamadas. En produccion con alto trafico, migrar a verificacion con google-auth-library (verifica localmente via clave publica de Google)
- **GOOGLE_WEB_CLIENT_ID obligatorio:** Si esta vacio, el sistema muestra error claro al usuario y no intenta autenticar
- **Sin Firebase Realtime Database:** Si en el futuro se necesitan notificaciones push via FCM, se necesitaria Firebase de todas formas

---

## Alternativas Consideradas

1. **Firebase Authentication como intermediario**
   - Rechazado: Complejidad innecesaria, errores de inicializacion multiple en web, peso de dependencias

2. **passport-google-oauth20 en servidor Node**
   - Rechazado: El backend es FastAPI (Python), no Node

3. **Supabase Auth**
   - Rechazado: Introduce vendor lock-in innecesario para este proyecto

---

## Archivos Modificados

- `backend/src/routes/auth.py` — `_verify_google_id_token()` + `POST /auth/google`
- `backend/src/schemas/base.py` — `GoogleAuthRequest`, `GoogleAuthResponse`
- `backend/src/models/users.py` — campo `google_id VARCHAR(128) UNIQUE`
- `backend/migrations/add_google_oauth_to_users.sql` — migracion SQL
- `frontend/lib/presentation/providers/auth_provider.dart` — `signInWithGoogle()`, singleton
- `frontend/lib/presentation/widgets/auth/google_sign_in_button.dart` — widget boton
- `frontend/lib/presentation/screens/auth/login_screen.dart` — boton Google
- `frontend/lib/presentation/screens/auth/register_screen.dart` — boton Google
- `frontend/lib/presentation/screens/onboarding/gdpr_consent_screen.dart` — onboarding nuevo usuario
- `frontend/lib/presentation/screens/onboarding/user_type_selection_screen.dart` — seleccion tipo
- `frontend/.env` — `GOOGLE_WEB_CLIENT_ID=`
- `.env` — `GOOGLE_WEB_CLIENT_ID=`
