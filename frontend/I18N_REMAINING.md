# i18n — Trabajo restante

**Fecha:** 2026-05-03
**Total strings restantes:** ~206
**es-ES.json actual:** 1341 keys

---

## Batch 4: Offers + Timeline (EN PROGRESO) — ~75 strings en 13 archivos

| Archivo | Strings | Seccion JSON probable |
|---|---|---|
| ~~`timeline_pages/tasacion_screen.dart`~~ | ~~18~~ | ~~`transaction`~~ | ✅ 9 locales |
| ~~`timeline_pages/notaria_screen.dart`~~ | ~~12~~ | ~~`transaction`~~ | ✅ 9 locales |
| ~~`timeline_pages/post_venta_screen.dart`~~ | ~~9~~ | ~~`transaction`~~ | ✅ 9 locales |
| ~~`timeline_pages/fein_screen.dart`~~ | ~~9~~ | ~~`transaction`~~ | ✅ 9 locales |
| ~~`arras_contract_review_screen.dart`~~ | ~~9~~ | ~~`arras_interview`~~ | ✅ 9 locales |
| ~~`timeline_pages/entrega_llaves_screen.dart`~~ | ~~5~~ | ~~`transaction`~~ | ✅ 9 locales |
| ~~`timeline_pages/notary_signing_page.dart`~~ | ~~3~~ | ~~`transaction`~~ | ✅ 9 locales |
| ~~`arras_shared_widgets.dart`~~ | ~~2~~ | ~~`arras_interview`~~ | ✅ 9 locales |
| ~~`arras_interview_screen.dart`~~ | ~~2~~ | ~~`arras_interview`~~ | ✅ 9 locales |
| ~~`arras_equity_analysis_screen.dart`~~ | ~~2~~ | ~~`arras_interview`~~ | ✅ 9 locales |
| ~~`arras_buyer_stepper_screen.dart`~~ | ~~2~~ | ~~`arras_interview`~~ | ✅ 9 locales |
| ~~`smart_bid_risk_screen.dart`~~ | ~~1~~ | ~~`smart_bid_risk`~~ | ✅ 9 locales |
| ~~`pre_offer_tax_summary_screen.dart`~~ | ~~1~~ | ~~`pre_offer_tax`~~ | ✅ 9 locales |

> Ruta base: `lib/presentation/screens/offers/`

---

## Batch 5: KYC + Solvency — ~34 strings

| Directorio | Strings |
|---|---|
| `screens/solvency/` | 24 |
| `screens/kyc/` | 10 |

---

## Batch 6: Chat + Visits — ~15 strings

| Directorio | Strings |
|---|---|
| `screens/visits/` | 14 |
| `screens/chat/` | 1 |

---

## Batch 7: Info + Lifestyle + Admin + Contracts — ~17 strings

| Directorio | Strings |
|---|---|
| `screens/lifestyle/` | 7 |
| `screens/admin/` | 7 |
| `screens/info/` | 3 |
| `screens/contracts/` | 1 (estimado) |

---

## Batch 8: Widgets — ~16 strings en 7 archivos

| Archivo | Strings |
|---|---|
| `widgets/property_listing/property_listing_item.dart` | 4 |
| `widgets/property/smart_explorer_card.dart` | 3 |
| `widgets/property/registry_link_widget.dart` | 3 |
| `widgets/open_street_map_widget.dart` | 3 |
| `widgets/property/legal_info_sheet.dart` | 1 |
| `widgets/property/legal_guide_button.dart` | 1 |
| `widgets/map/property_floating_card.dart` | 1 |

> Ruta base: `lib/presentation/widgets/`

---

## Screens sueltos — ~22 strings

| Archivo | Strings |
|---|---|
| `screens/property_listing_screen.dart` | 10 |
| `screens/not_found/` | 4 |
| `screens/notifications/` | 3 |
| `screens/user_profile_screen.dart` | 2 |
| `screens/settings/` | 2 |

---

## hintText / labelText en InputDecoration — ~23 strings

Repartidos en multiples archivos de screens (no contados en los totales anteriores).

---

## Traducciones pendientes a 8 locales

Las claves nuevas anadidas a es-ES.json en los batches 2-4 (offers, make_offer, property) necesitan traduccion a:
- en-US, en-GB, en-CA, fr-FR, fr-CA, ca-ES, eu-ES, gl-ES

---

## Verificacion final

- `flutter analyze` — cero errores
- `grep -rn "Text('" lib/presentation/ | grep -v ".tr()"` — verificar cero hardcoded
- Test visual en navegador cambiando idioma
