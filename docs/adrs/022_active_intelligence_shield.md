# ADR 022: Active Intelligence Shield 2.0

**Estado:** Aceptado
**Fecha:** 2026-04-23
**Autores:** @Architect, @Shield, @Jules

---

## Contexto

El "Escudo Anti-Agencias" original (Hito 3) era un filtro estatico basado en blacklists
de dominios de email (30+) y keywords profesionales en nombres. Este enfoque tiene una
limitacion critica: no detecta agentes profesionales que usan correos personales
(Gmail, Outlook) para registrarse en la plataforma.

El modelo de negocio P2P de InmuFacil requiere una segunda capa de defensa que analice
la huella digital del usuario a traves de fuentes OSINT (Open Source Intelligence).

---

## Decision

### Arquitectura de tres capas

```
Capa 1: Filtro Estatico (filters.py) -- Blacklist de dominios + keywords
    |
    v  (si pasa Capa 1)
Capa 2: Intelligence Shield (intelligence_shield.py) -- OSINT + IA
    |
    v  (en paralelo, post-registro)
Capa 3: Community Shield (reports.py) -- Denuncias P2P
```

### Capa 2: Intelligence Shield

- **Modulo:** `backend/src/utils/intelligence_shield.py`
- **Funcion principal:** `investigate_user_osint(email, full_name, phone)`
- **Vectores de deteccion:**
  - Telefono en portales inmobiliarios (Idealista, Fotocasa, etc.): +40 puntos
  - Nombre vinculado a perfiles profesionales (LinkedIn, directorios): +40 puntos
  - Email de dominio temporal/desechable: +20 puntos
- **Umbral de bloqueo:** >= 80 puntos (configurable via `RISK_THRESHOLD`)
- **APIs externas (simuladas, preparadas para produccion):**
  - `search_osint_sources`: Serper / Google Custom Search
  - `analyze_with_llm`: Gemini Vision API para clasificacion de perfil
- **Fallback:** Si las APIs fallan, score = 0 (permitir registro)
- **Trazabilidad:** Watermark ID unico (UUID) por investigacion

### Capa 3: Community Shield

- **Modelo:** `UserReport` (tabla `user_reports`)
  - `reporter_id`, `reported_id`, `reason_category`, `description`, `created_at`
  - Categorias: `profesional_camuflado`, `pide_comision`, `datos_inexactos`
- **Columna:** `report_count` en tabla `users`
- **Endpoint:** `POST /reports/report-agent`
  - Reporter debe ser `email_verified`
  - Prevencion de auto-denuncias y duplicados
- **Scoring:** +25 puntos por denuncia de usuario distinto (cap 100)
- **Re-investigacion:** Automatica al alcanzar 3 denuncias

### Notificaciones de Moderacion

- **Servicio:** `backend/src/services/moderation_alerts.py`
- **Remitente:** "Asistente IA InmuFacil <asistenteia@inmufacil.com>"
- **Destinatario:** Variable de entorno `ADMIN_EMAIL`
- **Triggers:**
  - Acumulacion de >= 3 denuncias comunitarias
  - Score OSINT > 90 (alerta inmediata CRITICAL)
- **Contenido:** Resumen de denuncias, score IA, datos del sospechoso, enlace al panel admin

### Eliminacion del duplicado legacy

- `backend/filters.py` (copia no importada) eliminado
- Filtro estatico centralizado en `backend/src/utils/filters.py`
- Tests en `tests/test_filters.py` alineados con ADR-021 (sin parametro `user_type`)

---

## Opciones Consideradas

### Opcion A: OSINT + IA con scoring ponderado (ELEGIDA)

- **Pros:** Detecta agentes con emails personales. Scoring configurable. APIs intercambiables.
  Fallback seguro. Trazabilidad via watermarks.
- **Contras:** Dependencia de APIs externas. Coste por consulta (Serper ~$0.003, Gemini variable).
  Latencia adicional en registro (~2-5 seg en produccion).
- **Estado:** Implementada con simulacion. Lista para conexion a APIs reales.

### Opcion B: Verificacion manual por admin

- Rechazada. No escala. Bloquea el flujo de registro.

### Opcion C: Solo denuncias comunitarias (sin IA)

- Insuficiente como unica capa. Un agente puede operar semanas antes de acumular denuncias.
  Complementaria, no sustitutiva.

---

## Consecuencias

### Positivas
- Deteccion de agentes con emails personales (gap anterior cerrado)
- Sistema de moderacion comunitario que complementa la IA
- Admin notificado automaticamente para accion rapida
- Tests completos (43 tests GREEN)

### Negativas
- Coste operativo de APIs externas (a evaluar en produccion)
- Latencia adicional en registro (mitigable con investigacion asincrona post-registro)

---

## Variables de Entorno Requeridas

| Variable | Descripcion | Ejemplo |
|---|---|---|
| `ADMIN_EMAIL` | Email del administrador para alertas | `admin@inmufacil.com` |
| `MODERATION_FROM` | Remitente de alertas de moderacion | `asistenteia@inmufacil.com` |
| `ADMIN_PANEL_URL` | URL del panel de administracion | `https://www.inmufacil.com/admin/users` |

---

## Deuda Tecnica

| Item | Descripcion | Prioridad |
|---|---|---|
| Serper API | Conectar `search_osint_sources` a API real | Alta |
| Gemini API | Conectar `analyze_with_llm` a google-genai SDK | Alta |
| Phone decryption | Descifrar telefono antes de investigacion OSINT | Media |
| Rate limiting | Limitar denuncias por usuario por dia | Baja |
| Report retraction | Permitir al usuario retirar su denuncia | Baja |
