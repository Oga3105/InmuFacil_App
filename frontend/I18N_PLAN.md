# Plan de Correccion i18n — InmuFacil
**Version:** 1.0 | **Fecha inicio:** 2026-05-08 | **Responsable:** @Linguist

---

## Estado global

| Idioma | Claves totales | Traduccion real | Estado |
|--------|---------------|-----------------|--------|
| es-ES  | 2.696         | 100%            | BASE   |
| en-US  | 2.696         | 66%             | CRITICO|
| en-GB  | 2.574         | 81%             | REVISAR|
| en-CA  | 2.617         | 81%             | REVISAR|
| fr-FR  | 2.657         | 59%             | CRITICO|
| fr-CA  | 2.617         | 80%             | REVISAR|
| ca-ES  | 2.779         | 46%             | CRITICO|
| va-ES  | 2.818         | 49%             | CRITICO|
| eu-ES  | 2.779         | 46%             | CRITICO|
| gl-ES  | 2.779         | 39%             | CRITICO|

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

- [ ] **A1** Añadir los 5 bloques faltantes a **es-ES** (base para fallback)
  - urgency.* (13 claves), transaction.* (74), arras_interview.* (26), visit_cancel.* (9), ai_consent.* (5)
- [ ] **A2** Añadir + traducir los 5 bloques a **en-US**
- [ ] **A3** Añadir + traducir los 5 bloques a **en-GB**
- [ ] **A4** Añadir + traducir los 5 bloques a **en-CA**
- [ ] **A5** Añadir + traducir los 5 bloques a **fr-FR**
- [ ] **A6** Añadir + traducir los 5 bloques a **fr-CA**
- [ ] **A7** Verificar que ca-ES, va-ES, eu-ES, gl-ES ya los tienen correctamente

---

## FASE B — Claves estructuralmente faltantes
> Prioridad: ALTA | Genera claves crudas en pantallas especificas

- [ ] **B1** Añadir bloque `ccaa.*` (19 claves geograficas) a en-GB, en-CA, fr-CA, fr-FR
  - Decision editorial: mantener nombres en español (comunidades autonomas) o traducir al idioma
- [ ] **B2** Añadir `info.what_is.savings_table.*` (9 claves) a fr-FR
- [ ] **B3** Añadir `arras_contract.legal_ref_cataluna` y `legal_ref_general` a fr-FR
- [ ] **B4** Añadir `kyc.dni` y `kyc.nie` a fr-FR (o mantener como siglas españolas)

---

## FASE C — Traduccion real de bloques en español
> Prioridad: ALTA | El usuario ve texto en español cuando ha seleccionado otro idioma

### C1 — Completar en-US (66% → 100%)
- [ ] Solvencia: `solvency_wizard.*`, `second_buyer.*`, `solvency_passport.*`
- [ ] Arras y timeline: `arras_buyer.*`, `arras_seller.*`, `timeline.*`
- [ ] KYC: bloques pendientes de `kyc.*`
- [ ] Perfil: `profile.*` pendientes
- [ ] Visitas: `visits.*` pendientes
- [ ] Notificaciones: `notifications.*` pendientes

### C2 — Completar fr-FR (59% → 85%+)
- [ ] Auth: `auth.*` pendientes
- [ ] Solvencia completa
- [ ] Arras y timeline
- [ ] Chat: `chat.*`
- [ ] Admin: `admin.*` (baja prioridad)

### C3 — Completar fr-CA (80% → 90%+)
- [ ] Alinear con fr-FR en los bloques que le faltan

### C4 — Completar en-GB y en-CA (81% → 90%+)
- [ ] Alinear con en-US en los bloques pendientes

### C5 — Completar ca-ES (46% → 80%+)
- [ ] Solvencia, arras, timeline, chat, admin, widgets
- [ ] Revision gramatical de lo existente (muchas copias del español)

### C6 — Completar va-ES (49% → 80%+)
- [ ] Mismos bloques que ca-ES
- [ ] Nota: va-ES comparte ~90% del vocabulario con ca-ES

### C7 — Completar eu-ES (46% → 80%+)
- [ ] Euskera requiere traduccion especializada
- [ ] Solvencia, arras, timeline, widgets

### C8 — Completar gl-ES (39% → 80%+)
- [ ] Es el idioma con menor cobertura
- [ ] Gallego: solvencia, arras, timeline, chat, admin, widgets completos

---

## FASE D — Hardcoded strings (no usan .tr())
> Prioridad: MEDIA | Siempre en español/ingles independientemente del idioma

- [ ] **D1** `auth/login_screen.dart` — `'InmuFácil'` → `'app.name'.tr()`
- [ ] **D2** `auth/register_screen.dart` — `'InmuFácil'` → `'app.name'.tr()`
- [ ] **D3** Revision manual de 13 archivos con 1 string potencialmente hardcoded

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
- [ ] **F2** Verificar que eu-ES y gl-ES tienen delegados correctos (tienen `ca` y `es` como fallback en GlobalMaterialLocalizations — OK por defecto)
- [ ] **F3** Verificar comportamiento de Material widgets en fr-CA (deberia usar fr-FR como fallback — revisar)

---

## REGISTRO DE PROGRESO

| Fecha      | Fase | Tarea | Resultado |
|------------|------|-------|-----------|
| 2026-05-07 | F1   | Delegate va-ES MaterialLocalizations | DONE |
| 2026-05-08 | -    | Auditoria inicial completada | DONE |

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
