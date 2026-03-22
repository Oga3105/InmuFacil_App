# API Reference — InmuFacil

**Version:** 3.0
**Base URL local:** `http://localhost:8000/api/v1`
**Base URL produccion:** `https://api.inmufacil.com/api/v1`
**Spec completa:** `/docs` (Swagger UI) o `/redoc`
**Autenticacion:** `Authorization: Bearer <jwt_token>` en todos los endpoints protegidos

---

## Convenciones

- **Content-Type:** `application/json` en todas las peticiones (excepto multipart)
- **Paginacion:** `?limit=<n>&offset=<n>` en endpoints de listado
- **Errores:** `{ "detail": "<mensaje>" }` con el HTTP status code apropiado
- **Importes monetarios:** Siempre enteros (int), nunca decimales
- **Fechas:** ISO 8601 (e.g., `2026-03-22T10:30:00Z`)

---

## Autenticacion — `/auth`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/auth/register` | No | Registro de usuario nuevo (anti-agency filter activo) |
| POST | `/auth/token` | No | Login con email+contrasena → JWT (form-urlencoded) |
| POST | `/auth/verify-email` | No | Verificacion MFA (token 6 digitos) |
| POST | `/auth/request-password-reset` | No | Solicitar reset de contrasena |
| POST | `/auth/reset-password` | No | Confirmar reset con token MFA |
| POST | `/auth/change-password` | Si | Cambiar contrasena (usuario autenticado) |
| POST | `/auth/google` | No | Login/registro con Google ID token |

### POST /auth/register
```json
// Body
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "full_name": "Juan Garcia",
  "user_type": "particular"  // "particular" | "profesional"
}

// Response 201
{
  "id": 1, "email": "user@example.com", "full_name": "Juan Garcia",
  "user_type": "particular", "email_verified": false, "dni_status": "sin_verificar"
}
```

### POST /auth/token
```
Content-Type: application/x-www-form-urlencoded
username=user@example.com&password=SecurePass123!

// Response 200
{ "access_token": "eyJ...", "token_type": "bearer" }
```

### POST /auth/google
```json
// Body
{ "google_id_token": "<Google ID token obtenido en cliente via google_sign_in>" }

// Response 200
{
  "access_token": "eyJ...",
  "token_type": "bearer",
  "is_new_user": true  // true = ir a onboarding, false = ir a home
}
```

---

## Usuarios — `/users`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| GET | `/users/me` | Si | Obtener perfil propio |
| PUT | `/users/me` | Si | Actualizar nombre y/o telefono |
| POST | `/users/me/photo` | Si | Subir/reemplazar foto de perfil (multipart) |
| DELETE | `/users/me/photo` | Si | Eliminar foto de perfil |

---

## Propiedades — `/properties`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| GET | `/properties` | No | Listado con filtros (precio, m2, habitaciones, tipo, lat/lon) |
| POST | `/properties` | Si | Crear propiedad (propietario) |
| GET | `/properties/{id}` | No | Detalle de propiedad |
| PUT | `/properties/{id}` | Si | Editar propiedad (solo propietario) |
| DELETE | `/properties/{id}` | Si | Eliminar propiedad (solo propietario) |
| POST | `/properties/{id}/photos` | Si | Subir fotos (multipart, hasta 10) |
| GET | `/properties/my` | Si | Mis propiedades publicadas |

### Filtros de busqueda (GET /properties)
```
?min_price=100000&max_price=300000
&min_surface=50&max_surface=120
&bedrooms=3
&property_type=piso
&lat=40.416&lon=-3.703&radius_km=5
&limit=20&offset=0
```

---

## Visitas — `/visits`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/visits` | Si | Solicitar visita a propiedad |
| GET | `/visits/my` | Si | Mis visitas (como comprador o vendedor) |
| PUT | `/visits/{id}/approve` | Si | Aprobar visita (solo propietario) |
| PUT | `/visits/{id}/complete` | Si | Marcar visita como completada |
| DELETE | `/visits/{id}` | Si | Cancelar visita |

---

## Ofertas — `/offers`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/offers` | Si | Crear oferta sobre propiedad |
| GET | `/offers/sent` | Si | Ofertas enviadas por el usuario |
| GET | `/offers/received` | Si | Ofertas recibidas (como propietario) |
| GET | `/offers/{id}` | Si | Detalle de oferta |
| PUT | `/offers/{id}/accept` | Si | Aceptar oferta (propietario) |
| PUT | `/offers/{id}/reject` | Si | Rechazar oferta (propietario) |
| PUT | `/offers/{id}/counteroffer` | Si | Enviar contraoferta |
| PUT | `/offers/{id}/details` | Si | Cuestionario legal (datos para contrato) |

---

## Chat — `/chat`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| GET | `/chat` | Si | Lista de conversaciones activas |
| GET | `/chat/{offer_id}` | Si | Mensajes de una conversacion |
| POST | `/chat/{offer_id}` | Si | Enviar mensaje |

---

## KYC — `/kyc`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/kyc/upload-document` | Si | Subir documento de identidad (DNI/NIE/Pasaporte) |
| GET | `/kyc/status` | Si | Estado de verificacion KYC |
| POST | `/kyc/liveness` | Si | Verificacion de vida (foto selfie) |

---

## Solvencia — `/solvency` y `/solvency-passport`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/solvency/profile` | Si | Crear perfil de solvencia |
| GET | `/solvency/passport` | Si | Obtener Solvency Passport propio |
| GET | `/solvency-passport/{user_id}/anonymised` | Si | Pasaporte anonimizado (para vendedor) |
| POST | `/solvency/second-buyer` | Si | Agregar segundo comprador |

---

## Contratos y Firma — `/contracts` y `/signature`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/contracts/{offer_id}/generate` | Si | Generar PDF de contrato de arras |
| GET | `/contracts/{offer_id}/download` | Si | Descargar PDF generado |
| POST | `/signature/request/{offer_id}` | Si | Solicitar firma digital |
| POST | `/signature/verify/{token}` | No | Simular click de firma (dev) |
| GET | `/signature/status/{offer_id}` | Si | Estado de la firma |

---

## Notaria — `/notaries`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| GET | `/notaries` | Si | Lista de notarios disponibles |
| POST | `/notaries/assign/{offer_id}` | Si | Asignar notario a oferta firmada |
| GET | `/notaries/dossier/{offer_id}` | Si | Generar dossier ZIP (SHA-256 manifest) |

---

## Financiacion — `/financing`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/financing/profile` | Si | Crear perfil hipotecario |
| GET | `/financing/simulation` | Si | Simular cuotas hipotecarias |
| GET | `/financing/offers` | Si | Ofertas hipotecarias (mock: iAhorro, BBVA, Santander) |

---

## Servicios de IA — `/ai`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/ai/description` | Si | Generar descripcion de propiedad con Gemini |
| POST | `/ai/generate` | Si | Generar contenido AI generico |
| GET | `/ai-consent` | Si | Obtener configuracion de consentimiento IA del usuario |
| PUT | `/ai-consent` | Si | Actualizar consentimiento IA (GDPR Art. 6.1.a) |
| GET | `/ai-consent/history` | Si | Historial de cambios de consentimiento |

---

## Servicios de Mercado — `/market-price`, `/comfort-index`, `/neighborhood-twins`, `/urban-growth`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| GET | `/market-price` | Si | Precio de mercado estimado por zona |
| GET | `/comfort-index/{property_id}` | Si | Indice de confort (ComfortRadar) |
| GET | `/neighborhood-twins/{lat}/{lon}` | Si | Barrios similares al de la propiedad |
| GET | `/urban-growth/{municipio}` | Si | Tendencias de crecimiento urbano |
| POST | `/price-validator` | Si | Validar precio vs mercado |

---

## Analytics — `/property-analytics`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| GET | `/property-analytics/{id}` | Si | Stats de visitas, ofertas e interacciones |
| GET | `/property-analytics/{id}/smart-bid` | Si | Analisis de riesgo de oferta (Smart Bid Risk) |

---

## Post-Venta — `/post-sale`, `/handover`, `/timeline`

| Metodo | Endpoint | Auth | Descripcion |
|---|---|---|---|
| POST | `/post-sale/cost-estimate` | Si | Estimacion de costes (ITP, notaria, registro) |
| POST | `/handover/initiate/{offer_id}` | Si | Iniciar traspaso de suministros |
| GET | `/timeline/{offer_id}` | Si | Estado completo del timeline de compraventa |

---

## Otros

| Endpoint | Descripcion |
|---|---|
| GET `/health` | Estado del sistema (DB + cifrado) |
| GET `/docs` | Swagger UI interactivo |
| POST `/leads` | Captura de email en pagina 404 (lead magnet) |
| GET `/notifications` | Notificaciones del usuario |
| GET `/favorites` | Propiedades favoritas |
| GET `/legal-guides` | Guias legales por tipo de transaccion |
| GET `/nota-simple/{property_id}` | Nota simple de la propiedad |
