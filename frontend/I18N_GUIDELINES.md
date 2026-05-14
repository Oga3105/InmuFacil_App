# Internationalization (i18n) Guidelines

## 🌍 Overview

InmuFácil supports 10 regional language variants with strict i18n protocols.

---

## 🚫 REGLA DE ORO: NO HARDCODED STRINGS

**PROHIBIDO:**
```dart
Text('Hola Mundo')
Text('Welcome')
```

**CORRECTO:**
```dart
Text('home.welcome').tr()
Text('auth.login_button').tr()
```

---

## 📋 Supported Locales

| Locale | Language | Region |
|--------|----------|--------|
| `es-ES` | Español | España (Base) |
| `ca-ES` | Català | Catalunya |
| `eu-ES` | Euskara | Euskadi |
| `gl-ES` | Galego | Galicia |
| `en-GB` | English | United Kingdom |
| `en-US` | English | United States |
| `en-CA` | English | Canada |
| `fr-FR` | Français | France |
| `fr-CA` | Français | Canada |
| `va-ES` | Valenciano | Comunitat Valenciana |

**Fallback:** `es-ES` (Spanish Spain)

---

## 🔑 Key Naming Convention

### Structure
```
feature.component.element
```

### Examples
```json
{
  "auth.login_title": "Iniciar Sesión",
  "auth.login_button": "Entrar",
  "home.welcome": "Bienvenido",
  "property.details.price_label": "Precio",
  "common.save": "Guardar"
}
```

### Rules
- Use **snake_case** for keys
- Be **semantic** (describe purpose, not content)
- Group by **feature** first, then **component**
- Use `common.*` for shared strings

---

## 📝 Usage in Widgets

### Basic Text
```dart
Text('auth.login_title').tr()
```

### With Parameters
```dart
Text('welcome_user').tr(namedArgs: {'name': userName})
```

JSON:
```json
{
  "welcome_user": "Bienvenido, {name}"
}
```

### Plurals
```dart
Text('items_count').plural(itemCount)
```

JSON:
```json
{
  "items_count": {
    "zero": "Sin elementos",
    "one": "1 elemento",
    "other": "{} elementos"
  }
}
```

---

## 🛠️ Adding New Translations

### 1. Add Key to ALL Language Files

**es-ES.json:**
```json
{
  "property.new_feature": "Nueva característica"
}
```

**en-GB.json:**
```json
{
  "property.new_feature": "New feature"
}
```

**Repeat for all 10 locales.**

### 2. Use in Code
```dart
Text('property.new_feature').tr()
```

---

## 🎯 Common Patterns

### Form Labels
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'auth.email_label'.tr(),
    hintText: 'auth.email_hint'.tr(),
  ),
)
```

### Buttons
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('common.save').tr(),
)
```

### Error Messages
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('errors.network_error').tr()),
);
```

---

## ✅ Checklist for New Features

- [ ] Add all strings to `es-ES.json` (base)
- [ ] Translate to all 9 other locales
- [ ] Use `.tr()` in all widgets
- [ ] Test with different locales
- [ ] No hardcoded strings remain

---

## 🔍 Validation

### Pre-commit Check
```bash
# Search for hardcoded strings (should return nothing)
grep -r "Text('" lib/presentation/
```

### Locale Switching
```dart
// Change locale programmatically
context.setLocale(Locale('ca', 'ES'));
```

---

## 📚 Resources

- **Translation Files:** `assets/translations/`
- **EasyLocalization Docs:** https://pub.dev/packages/easy_localization
- **Base Locale:** `es-ES` (Spanish Spain)

---

## 🚨 Enforcement

**@FrontendProxy and @UIBuilder** will reject any PR with hardcoded strings.

All text must come from translation files.
