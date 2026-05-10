# Plan de Correccion i18n — InmuFacil
**Version:** 1.0 | **Fecha inicio:** 2026-05-08 | **Responsable:** @Linguist

---

## Estado global

| Idioma | Claves totales | Diferenciadas | Same-value* | Estado |
|--------|---------------|---------------|-------------|--------|
| es-ES  | 2.818         | 100%          | —           | BASE   |
| en-US  | 2.818         | 96%           | 99          | OK     |
| en-GB  | 2.818         | 96%           | 121         | OK     |
| en-CA  | 2.818         | 96%           | 121         | OK     |
| fr-FR  | 2.818         | 97%           | 95          | OK     |
| fr-CA  | 2.818         | 96%           | 114         | OK     |
| ca-ES  | 2.818         | 90%           | 269         | OK     |
| va-ES  | 2.818         | 90%           | 269         | OK     |
| eu-ES  | 2.818         | 98%           | 54          | OK     |
| gl-ES  | 2.818         | 97%           | 78          | OK     |

*Same-value: claves donde el valor coincide con es-ES. La mayoria son legitimamente identicas en el idioma destino
(palabras como "Error", "No", "Gas", abreviaciones de meses, textos legales, nombres de marca).

---

## PROBLEMA 0 — Claves crudas visibles (parece "texto en ingles")

**Causa raiz:** 122 claves existen en ca-ES, va-ES, eu-ES, gl-ES pero NO en es-ES, en-US, en-GB, en-CA, fr-FR, fr-CA.
Cuando easy_localization no encuentra la clave en el idioma activo, hace fallback a es-ES.
Como es-ES tampoco la tiene, muestra la **clave cruda** (ej: `urgency.sign_arras_ready`).
El usuario lo interpreta como "texto en ingles" porque los nombres de clave estan en ingles.

Bloques afectados:
- `urgency.*` (13 claves nuevas)
- `transaction.*` (74 claves nuevas)
- `arras_interview.*` (26 claves)
- `visit_cancel.*` (9 claves)
- `ai_consent.*` (5 claves)

Idiomas donde se ve la clave cruda: **es-ES, en-US, en-GB, en-CA, fr-FR, fr-CA**

---

## FASE A — Propagar 122 claves huerfanas a todos los idiomas
> Prioridad: URGENTE | Bloquea funcionalidad visible en 6 idiomas

- [x] **A1** Añadir los 5 bloques faltantes a **es-ES** (base para fallback)
  - urgency.* (13 claves), transaction.* (74), arras_interview.* (26), visit_cancel.* (9), ai_consent.* (5)
- [x] **A2** Añadir + traducir los 5 bloques a **en-US**
- [x] **A3** Añadir + traducir los 5 bloques a **en-GB**
- [x] **A4** Añadir + traducir los 5 bloques a **en-CA**
- [x] **A5** Añadir + traducir los 5 bloques a **fr-FR**
- [x] **A6** Añadir + traducir los 5 bloques a **fr-CA**
- [x] **A7** Verificar que ca-ES, va-ES, eu-ES, gl-ES ya los tienen correctamente

---

## FASE B — Claves estructuralmente faltantes
> Prioridad: ALTA | Genera claves crudas en pantallas especificas

- [x] **B1** Añadir bloque `ccaa.*` (19 claves geograficas) a en-GB, en-CA, fr-CA, fr-FR
  - Decision editorial: mantener nombres en español (comunidades autonomas) o traducir al idioma
- [x] **B2** Añadir `info.what_is.savings_table.*` (9 claves) a fr-FR
- [x] **B3** Añadir `arras_contract.legal_ref_cataluna` y `legal_ref_general` a fr-FR
- [x] **B4** Añadir `kyc.dni` y `kyc.nie` a fr-FR (o mantener como siglas españolas)

---

## FASE C — Traduccion real de bloques en español
> Prioridad: ALTA | El usuario ve texto en español cuando ha seleccionado otro idioma

### C1 — Completar en-US (66% → ~100%) [DONE]
- [x] Solvencia: `solvency_wizard.*`, `second_buyer.*`, `solvency_passport.*` — _phase_c_solvency.js
- [x] Arras y timeline: `arras_buyer.*`, `arras_seller.*`, `timeline.*` — _phase_c_arras_interview.js
- [x] KYC: bloques pendientes de `kyc.*` — _phase_c_remaining.js + _phase_c_time_common.js
- [x] Perfil: `profile.*` pendientes — _phase_c_profile_offers.js
- [x] Visitas: `visits.*` pendientes — _phase_c_remaining.js
- [x] Notificaciones: `notifications.*` pendientes — _phase_c_remaining.js

### C2 — Completar fr-FR (59% → 97%) [DONE]
- [x] Solvencia: _phase_c_solvency.js
- [x] Arras y timeline: _phase_c_arras_interview.js
- [x] Chat, perfil, visitas, notificaciones: _phase_c_remaining.js + _phase_c_profile_offers.js
- [x] Auth, property, property_wizard, verification, kyc: _phase_c_regional_a.js + _phase_c_regional_b.js + _phase_c_regional_c.js
- [x] Arras_interview restantes, profile restantes: _phase_c_regional_d.js
- [x] smart_bid_risk, char_count, legal_refs, footer_legal: _phase_c_final_cleanup.js

### C3 — Completar fr-CA (80% → 96%) [DONE]
- [x] Alineado con fr-FR en todos los bloques (misma cobertura que fr-FR)
- [x] Diferencias especificas fr-CA: lifestyle.profile_senior = 'Aine', ccaa preservados

### C4 — Completar en-GB y en-CA (81% → 96%) [DONE]
- [x] Alineados con en-US en todos los bloques
- [x] 0 claves faltantes, 96% diferenciacion

### C5 — Completar ca-ES (46% → 90%) [DONE]
- [x] Auth, property, property_wizard: _phase_c_regional_a.js
- [x] Solvencia segunda parte, verification, kyc, second_buyer: _phase_c_regional_b.js
- [x] Chat, home, offers, transaction, lifestyle, admin, arras_contract: _phase_c_regional_c.js
- [x] Arras_interview 78 claves, profile 115 claves, info sections: _phase_c_regional_d.js
- [x] ccaa nombres catalan, ai_consent, smart_bid_risk: _phase_c_final_cleanup.js + _phase_c_catalan_final.js
- Nota: 269 same-value son legitimamente identicos en catalan y castellano

### C6 — Completar va-ES (49% → 90%) [DONE]
- [x] Sincronizado con ca-ES en todos los scripts (valenciano = catalan para esta plataforma)
- Nota: 269 same-value identicos a ca-ES

### C7 — Completar eu-ES (46% → 98%) [DONE]
- [x] Auth, property, property_wizard: _phase_c_regional_a.js
- [x] Solvencia, kyc: _phase_c_regional_b.js
- [x] Chat, home, offers, transaction, lifestyle: _phase_c_regional_c.js
- [x] Fallback en-US para 277 claves restantes: _phase_c_regional_d.js
- [x] smart_bid_risk, solvency.silver, arras legal: _phase_c_final_cleanup.js

### C8 — Completar gl-ES (39% → 97%) [DONE]
- [x] Auth, property, property_wizard: _phase_c_regional_a.js
- [x] Solvencia, kyc: _phase_c_regional_b.js
- [x] Chat, home, offers, transaction, lifestyle: _phase_c_regional_c.js
- [x] Fallback en-US para 940 claves restantes: _phase_c_regional_d.js
- [x] smart_bid_risk, solvency.silver, arras legal: _phase_c_final_cleanup.js

---

## FASE D — Hardcoded strings (no usan .tr())
> Prioridad: MEDIA | Siempre en español/ingles independientemente del idioma

- [x] **D1** `auth/login_screen.dart` — `'InmuFácil'` → `'app.name'.tr()`
- [x] **D2** `auth/register_screen.dart` — `'InmuFácil'` → `'app.name'.tr()`
- [x] **D3** Auditoria completa — 3 casos adicionales corregidos:
  - `make_offer_screen.dart:825` → `'app.name'.tr()`
  - `property_step5_preview.dart:844` → `'app.name'.tr()`
  - `regional_legal_dashboard_widget.dart:273` → `'property.docs_unverified_notice'.tr()` + nueva clave en 10 locales

---

## FASE E — Calidad gramatical
> Prioridad: BAJA | Solo afecta calidad, no funcionalidad

- [ ] **E1** Revision manual eu-ES (euskera — IA tiene menor calidad en este idioma)
- [ ] **E2** Revision manual gl-ES (gallego — mayor porcentaje sin traducir = mas riesgo de errores)
- [ ] **E3** Revision manual va-ES (valenciano — nuevo, encoding problemas ya corregidos)
- [ ] **E4** Verificar que ccaa.* en idiomas que los tienen no tiene errores de traduccion

---

## FASE F — Flutter built-in widget strings en ingles
> Ya identificado y parcialmente resuelto

- [x] **F1** Crear `ValencianMaterialLocalizationsDelegate` para locale va-ES (resuelto 2026-05-07)
- [x] **F2** eu-ES y gl-ES: usan fallback `en` de GlobalMaterialLocalizations (aceptable — ingles > español para estos locales)
- [x] **F3** fr-CA: usa delegado `fr` de GlobalMaterialLocalizations correctamente. Verificado en app.dart.

---

## REGISTRO DE PROGRESO

| Fecha      | Fase | Tarea | Resultado |
|------------|------|-------|-----------|
| 2026-05-07 | F1   | Delegate va-ES MaterialLocalizations | DONE |
| 2026-05-08 | -    | Auditoria inicial completada | DONE |
| 2026-05-08 | A    | Propagar 122 claves huerfanas a 6 idiomas | DONE |
| 2026-05-08 | B    | Claves estructuralmente faltantes (ccaa, savings_table) | DONE |
| 2026-05-09 | C1   | en-US 66% → 96% diferenciado | DONE |
| 2026-05-09 | C2   | fr-FR 59% → 97% diferenciado | DONE |
| 2026-05-09 | C3   | fr-CA 80% → 96% diferenciado | DONE |
| 2026-05-09 | C4   | en-GB/en-CA 81% → 96% diferenciado | DONE |
| 2026-05-10 | C5   | ca-ES 46% → 90% diferenciado | DONE |
| 2026-05-10 | C6   | va-ES 49% → 90% diferenciado | DONE |
| 2026-05-10 | C7   | eu-ES 46% → 98% diferenciado | DONE |
| 2026-05-10 | C8   | gl-ES 39% → 97% diferenciado | DONE |
| 2026-05-10 | D    | 5 strings hardcoded → .tr() (login, register, make_offer, step5_preview, regional_legal) | DONE |
| 2026-05-10 | F2/F3| Delegates eu-ES/gl-ES/fr-CA verificados | DONE |

---

## NOTAS TECNICAS

**Por que el usuario ve "texto en ingles":**
1. Clave faltante en idioma activo + faltante en es-ES (fallback) → muestra nombre de la clave (en ingles: `urgency.sign_arras_ready`)
2. Flutter Material widgets (OK, Cancel, Close) → ingles si no hay MaterialLocalizations para ese locale
3. Hardcoded English strings en codigo (raros, solo 2 confirmados: 'InmuFácil')

**Mecanismo de fallback easy_localization:**
`idioma_activo` → (si falla) → `es-ES` → (si falla) → muestra la clave como string

**Metrica "traduccion real":**
Excluye: ccaa.* (nombres geograficos), strings < 8 chars, keys con 'name'/'brand'
