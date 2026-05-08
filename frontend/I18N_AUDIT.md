# Auditoria i18n — InmuFacil
**Fecha:** 2026-05-08 | **Agente:** @Linguist + Piloto Explore | **Version:** 1.0

---

## RESUMEN EJECUTIVO

| Idioma | Total claves | Faltan vs es-ES | Sin traducir (mismo valor) | Traduccion real |
|--------|-------------|-----------------|----------------------------|-----------------|
| es-ES  | 2.696       | 0               | 0                          | 100%            |
| en-US  | 2.696       | 0               | ~921                       | **66%**         |
| en-GB  | 2.574       | 122             | ~477                       | **81%**         |
| en-CA  | 2.617       | 122             | ~498                       | **81%**         |
| fr-FR  | 2.657       | 39              | ~1.098                     | **59%**         |
| fr-CA  | 2.617       | 122             | ~532                       | **80%**         |
| ca-ES  | 2.779       | 39              | ~1.500                     | **46%**         |
| va-ES  | 2.818       | 0 (+122 extra)  | ~1.434                     | **49%**         |
| eu-ES  | 2.779       | 39              | ~1.510                     | **46%**         |
| gl-ES  | 2.779       | 39              | ~1.702                     | **39%**         |

> "Sin traducir" = valor identico al español (posible copia sin traducir), excluyendo nombres propios, ccaa y terminos internacionales.

---

## CAPA 1 — HARDCODED STRINGS (No usan .tr())

### Criticos (visibles al usuario)
| Archivo | String | Impacto |
|---------|--------|---------|
| `auth/login_screen.dart` | `'InmuFácil'` | Nombre de marca — deberia ser `'app.name'.tr()` |
| `auth/register_screen.dart` | `'InmuFácil'` | Idem |

### Decorativos / Aceptables (no requieren traduccion)
| Archivo | String | Razon |
|---------|--------|-------|
| `not_found/not_found_screen.dart` | `'['`, `'SECURE_LAYER_V2'`, `']'` | Elementos decorativos UI |
| `offers/arras_buyer_stepper_screen.dart` | `'5%'`, `'20%'` | Valores numericos de slider |
| `solvency/solvency_wizard_screen.dart` | `'0%'`, `'80%'` | Valores numericos de slider |

### A revisar manualmente (~13 archivos, 1 string cada uno)
Estos fueron detectados por el piloto pero requieren revision manual para confirmar si son realmente visibles al usuario o contextos tecnicos (tokens, IDs, etc.).

---

## CAPA 2 — CLAVES FALTANTES EN JSONS

### Claves faltantes comunes (presentes en es-ES, ausentes en varios idiomas)

**Bloque `ccaa.*` — Comunidades Autonomas (19 claves)**
Faltan en: en-GB, en-CA, fr-FR, fr-CA, ca-ES, eu-ES, gl-ES
> Las CCAA son nombres propios geograficos — es discutible si deben traducirse o mantenerse en español.
> En fr-FR y en-US probablemente deberian quedar en español o con el nombre oficial.

**Bloque `kyc.*` (2 claves)**
`kyc.dni`, `kyc.nie` — faltan en fr-FR
> Son siglas legales españolas — aceptable mantenerlas en español.

**Bloque `info.what_is.savings_table.*` (9 claves)**
Faltan en: fr-FR
> Tabla de comparativa de ahorros — texto importante, necesita traduccion.

**Bloque `arras_contract.*` (2 claves)**
`arras_contract.legal_ref_cataluna`, `arras_contract.legal_ref_general` — faltan en fr-FR
> Referencias legales — deberian existir.

### Claves extra en va-ES que NO existen en los otros 9 idiomas (122 claves)
Estos bloques fueron creados al generar el locale valenciano pero nunca se propagaron al resto:

| Bloque | Claves | Descripcion |
|--------|--------|-------------|
| `urgency.*` | 13 | Mensajes de urgencia del dashboard |
| `transaction.*` | 74 | Estados y CTAs de transaccion |
| `arras_interview.*` | 26 | Entrevista arras comprador/vendedor |
| `visit_cancel.*` | 9 | Cancelacion de visita |
| `ai_consent.*` | 5 | Consentimiento IA |

**Estas 122 claves faltan en es-ES, en-US, en-GB, en-CA, fr-FR, fr-CA, ca-ES, eu-ES y gl-ES.**
Si hay pantallas que las usan, en esos 9 idiomas la app crashearia o mostraria la clave cruda.

---

## CAPA 3 — CALIDAD DE TRADUCCION (valores identicos al español)

### Situacion critica (menos del 60% traducido)

**fr-FR (59%):** ~1.098 claves con valor en español
- Ejemplos detectados: `app.name`, `auth.copyright_secure`, `auth.no_intermediaries`, `auth.buy_sell_no_fees`, `auth.search_to_notary`, pantallas completas de solvencia, arras y timeline.

**gl-ES (39%):** ~1.702 claves con valor en español
- Es el idioma con menor cobertura real. Muchos bloques de solvencia, timeline y contrato aparecen en español.

**ca-ES (46%):** ~1.500 claves con valor en español
- Pantallas de administracion, chat, solvencia, visitas y widgets aparecen en español.

**eu-ES (46%):** ~1.510 claves con valor en español
- Similar a ca-ES. Bloques de auth, solvencia y timeline con valores en español.

### Situacion mejorable (60-85% traducido)

**en-US (66%):** ~921 claves con valor en español
- Inesperado para el idioma mas usado. Muchos bloques de arras, timeline y solvencia estan en español.

**va-ES (49%):** ~1.434 claves con valor en español
- Al ser nuevo, hereda el mismo problema que ca-ES en muchos bloques.

**fr-CA (80%), en-GB (81%), en-CA (81%):** Cobertura razonable pero mejorable.

---

## INVENTARIO POR PANTALLA

### Pantallas con mayor riesgo (mucho texto, poco traducido)

| Pantalla | Archivo | Riesgo estimado |
|----------|---------|-----------------|
| Perfil de usuario | `user_profile_screen.dart` | ALTO — 337 lineas de cambios, bloques complejos |
| Wizard solvencia | `solvency_wizard_screen.dart` | ALTO — flujo multi-paso con strings dinamicos |
| Arras comprador | `arras_buyer_stepper_screen.dart` | ALTO — contrato legal con strings largos |
| Arras vendedor | `arras_seller_stepper_screen.dart` | ALTO — idem |
| Chat detalle | `chat_detail_screen.dart` | MEDIO |
| Timeline tasacion | `tasacion_screen.dart` | MEDIO |
| Timeline notaria | `notaria_screen.dart` | MEDIO |
| Timeline FEIN | `fein_screen.dart` | MEDIO |
| KYC verificacion | `identity_verification_screen.dart` | MEDIO |
| Admin analytics | `admin_ai_analytics_screen.dart` | BAJO (solo admin) |

### Widgets compartidos (impacto en toda la app)
| Widget | Archivo | Issue |
|--------|---------|-------|
| Selector de idioma | `language_selector_widget.dart` | OK |
| AppBar back button | `app_bar_back_button.dart` | Corregido hoy |
| Property floating card | `property_floating_card.dart` | Revisar |
| Filter sidebar | `filter_sidebar.dart` | Revisar |
| Property listing item | `property_listing_item.dart` | Revisar |
| Legal info sheet | `legal_info_sheet.dart` | Revisar |

---

## PLAN DE CORRECCION (Priorizado)

### FASE A — Critico (bloquea funcionalidad)
1. Propagar las 122 claves de `va-ES` que faltan en los otros 9 idiomas
   - Bloques: `urgency.*`, `transaction.*`, `arras_interview.*`, `visit_cancel.*`, `ai_consent.*`
   - Si hay pantallas que usan estas claves, en 9 idiomas se ve la clave cruda

### FASE B — Alta prioridad (visible por el usuario)
2. Traducir bloques con 0% de traduccion en fr-FR, gl-ES, eu-ES:
   - Pantallas de solvencia (~80 claves)
   - Pantallas de arras/timeline (~120 claves)
   - Pantallas de contrato (~40 claves)
3. Completar en-US (66%) — sorprendente porque es el idioma global

### FASE C — Media prioridad
4. Anadir bloque `ccaa.*` a en-GB, en-CA, fr-CA (decision editorial: traducir o mantener en español)
5. Completar `info.what_is.savings_table.*` en fr-FR (9 claves)
6. Revisar y corregir los 13 archivos con 1 hardcoded string potencial

### FASE D — Mantenimiento
7. Sustituir `'InmuFácil'` hardcoded en login/register por `'app.name'.tr()`
8. Revision gramatical manual de va-ES y eu-ES (idiomas menos comunes en IA)

---

## NOTA METODOLOGICA

La metrica "traduccion real" excluye:
- Claves del bloque `ccaa.*` (nombres geograficos, pueden ser internacionales)
- Claves con `name`, `brand` en el nombre
- Strings de menos de 8 caracteres (acronimos, codigos)

Los porcentajes son conservadores — la situacion real puede ser peor en idiomas como gl-ES y eu-ES donde la IA tiene menor calidad de generacion.
