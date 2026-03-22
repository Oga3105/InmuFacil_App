# ADR 019: Gestion de Consentimiento IA (RGPD Art. 6.1.a)

**Estado:** Aceptado
**Fecha:** 2026-03-22
**Autores:** @Shield, @Architect

---

## Contexto

InmuFacil usa servicios de IA (Gemini) que procesan datos personales del usuario (fotos de documentos para KYC, descripciones de propiedades que pueden contener ubicacion, fotos del inmueble, etc.). El Reglamento General de Proteccion de Datos (RGPD) de la UE, en su Articulo 6.1.a, establece que el tratamiento de datos personales es licito cuando "el interesado dio su consentimiento para el tratamiento de sus datos personales para uno o varios fines especificos".

Sin un mecanismo de consentimiento explicito, el uso de IA sobre datos del usuario seria ilegal bajo RGPD.

---

## Decision

Implementar un sistema completo de **gestion de consentimiento IA** con las siguientes caracteristicas:

### 1. Consentimiento granular

El usuario puede aceptar o rechazar de forma independiente cada tipo de uso de IA:
- **Analisis KYC**: Gemini Vision analiza el documento de identidad
- **Generacion de descripcion**: Gemini genera descripcion de la propiedad
- **Analisis de mercado**: IA analiza tendencias de precios en la zona
- **Personalizacion**: IA personaliza resultados de busqueda segun comportamiento

### 2. Flujo de consentimiento

**Nuevo usuario via Google OAuth:**
1. Pantalla `GdprConsentScreen` → informacion clara sobre uso de IA
2. El usuario puede aceptar todo, rechazar todo, o configurar individualmente
3. Si rechaza: puede continuar usando la plataforma sin funciones IA
4. El consentimiento queda registrado en la base de datos con timestamp

**Usuario existente:**
- Accede a `Ajustes → Historial de consentimiento IA` (`/settings/ai-consent-history`)
- Puede cambiar su consentimiento en cualquier momento
- Cada cambio queda registrado en el historial (audit trail)

### 3. Implementacion tecnica

**Backend:**
- Modelo de datos con flag por tipo de consentimiento + timestamps
- Endpoint `GET /ai-consent` — obtener configuracion actual
- Endpoint `PUT /ai-consent` — actualizar consentimiento
- Endpoint `GET /ai-consent/history` — historial de cambios

**Frontend:**
- `AiConsentHistoryScreen` — pantalla de historial visible desde ajustes
- `GdprConsentScreen` — onboarding para nuevos usuarios Google
- Antes de cualquier llamada a IA: verificar que el usuario tiene consentimiento activo para ese tipo

**Validacion en backend:**
- Antes de procesar cualquier solicitud de IA, el endpoint verifica que `user.ai_consent_<tipo> == True`
- Si no hay consentimiento: HTTP 403 con mensaje explicativo

### 4. Derecho al olvido

El sistema soporta la eliminacion completa del historial de consentimiento como parte del "derecho al olvido" (RGPD Art. 17). Esto se gestiona junto con el borrado de cuenta.

---

## Consecuencias

### Positivas
- Cumplimiento legal RGPD Art. 6.1.a — consentimiento explicito e informado
- Trazabilidad completa (audit trail) de todos los cambios de consentimiento
- Arquitectura granular permite a los usuarios controlar exactamente que IA se aplica a sus datos
- Protege a InmuFacil de sanciones de la AEPD (Agencia Espanola de Proteccion de Datos)

### Negativas
- Usuarios que rechazan el consentimiento KYC no pueden completar la verificacion de identidad, lo que los bloquea para ciertas operaciones (hacer ofertas, acceder al dossier notarial)
- Incremento de complejidad en los flujos de onboarding

---

## Alternativas Consideradas

1. **Consentimiento unico para toda la IA**
   - Rechazado: Demasiado permisivo, no cumple el principio de minimizacion del RGPD

2. **Consentimiento implicito (terminos y condiciones generales)**
   - Rechazado: No valido bajo RGPD — el consentimiento debe ser "libre, especifico, informado e inequivoco"

3. **Sin consentimiento (argumento de interes legitimo)**
   - Rechazado: El analisis de documentos de identidad con IA no puede justificarse por interes legitimo
