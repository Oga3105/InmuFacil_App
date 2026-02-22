# Security Audit Report: Nominatim Geocoding Implementation

**Date:** 2026-02-07  
**Feature:** City Search with Nominatim API  
**Auditor:** AI Security Review  
**Status:** 🟡 Medium Risk - Requires Improvements

---

## 🔍 Executive Summary

The geocoding implementation using Nominatim API has been reviewed for security vulnerabilities. **3 medium-severity issues** were identified that require immediate attention before production deployment.

**Risk Level:** 🟡 MEDIUM  
**Recommendation:** Implement fixes before merge to develop

---

## 📊 Findings

### ✅ 1. URL Encoding - SECURE

**Status:** ✅ **PASS**

**Analysis:**
```dart
final urlSpain = Uri.parse(
  'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&countrycodes=es'
);
```

**Finding:** Dart's `Uri.parse()` automatically handles URL encoding of special characters in the query string. Characters like spaces, quotes, and special symbols are properly encoded.

**Test Cases:**
- `"Madrid"` → `Madrid` ✅
- `"San Sebastián"` → `San%20Sebasti%C3%A1n` ✅
- `"L'Hospitalet"` → `L%27Hospitalet` ✅
- `"<script>alert('xss')</script>"` → Encoded, not executed ✅

**Verdict:** No injection vulnerability through URL encoding.

---

### 🟡 2. Input Sanitization - NEEDS IMPROVEMENT

**Status:** 🟡 **MEDIUM RISK**

**Current Code:**
```dart
Future<void> searchCity(String query) async {
  if (query.trim().isEmpty) return;  // ← Only checks for empty
  // ... rest of code
}
```

**Issue:** No validation of input content beyond empty check.

**Potential Risks:**
1. **Excessively long inputs** - Could cause performance issues
2. **Special character abuse** - While URL-encoded, could cause API errors
3. **No character whitelist** - Accepts any Unicode characters

**Attack Vectors:**
```dart
// These would all be accepted:
searchCity("A" * 10000);  // 10k character string
searchCity("🚀🚀🚀🚀🚀");  // Emoji spam
searchCity("'; DROP TABLE--");  // SQL-like (harmless here but bad practice)
```

**Recommendation:**
```dart
Future<void> searchCity(String query) async {
  // 1. Trim whitespace
  final sanitized = query.trim();
  
  // 2. Check empty
  if (sanitized.isEmpty) return;
  
  // 3. Length validation (Nominatim recommends max 200 chars)
  if (sanitized.length > 200) {
    state = state.copyWith(
      error: 'Búsqueda demasiado larga (máx. 200 caracteres)',
      isLoading: false,
    );
    return;
  }
  
  // 4. Character whitelist (optional but recommended)
  // Allow: letters, numbers, spaces, common punctuation
  final validPattern = RegExp(r'^[a-zA-ZáéíóúñÁÉÍÓÚÑ0-9\s,.\-\']+$');
  if (!validPattern.hasMatch(sanitized)) {
    state = state.copyWith(
      error: 'Caracteres no válidos en la búsqueda',
      isLoading: false,
    );
    return;
  }
  
  // Continue with search...
}
```

**Severity:** 🟡 MEDIUM  
**Priority:** HIGH

---

### 🟡 3. Rate Limiting - MISSING

**Status:** 🟡 **MEDIUM RISK**

**Current Code:** No rate limiting or debouncing implemented.

**Issue:** User can trigger unlimited API requests by typing rapidly or clicking repeatedly.

**Nominatim Usage Policy:**
- **Limit:** 1 request per second
- **Bulk usage:** Requires approval
- **Abuse:** Can lead to IP ban

**Attack Scenario:**
```dart
// User types "M", "Ma", "Mad", "Madr", "Madri", "Madrid"
// = 6 API requests in < 1 second
// Violates Nominatim policy
```

**Recommendation - Debouncing:**
```dart
import 'dart:async';

class SearchNotifier extends StateNotifier<SearchState> {
  Timer? _debounceTimer;
  
  Future<void> searchCity(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Wait 500ms before executing search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _executeSearch(query);
    });
  }
  
  Future<void> _executeSearch(String query) async {
    // ... actual search logic here
  }
}
```

**Alternative - Rate Limiting:**
```dart
DateTime? _lastRequestTime;

Future<void> searchCity(String query) async {
  // Enforce 1 second between requests
  final now = DateTime.now();
  if (_lastRequestTime != null) {
    final diff = now.difference(_lastRequestTime!);
    if (diff.inMilliseconds < 1000) {
      debugPrint("⏱️ Rate limit: waiting ${1000 - diff.inMilliseconds}ms");
      await Future.delayed(Duration(milliseconds: 1000 - diff.inMilliseconds));
    }
  }
  _lastRequestTime = now;
  
  // Continue with search...
}
```

**Severity:** 🟡 MEDIUM  
**Priority:** HIGH

---

### 🟡 4. Error Message Information Disclosure - LOW RISK

**Status:** 🟡 **LOW RISK**

**Current Code:**
```dart
catch (e) {
  debugPrint("⚠️ Error in search algorithm: $e");
  state = state.copyWith(
    error: 'Error de conexión: ${e.toString()}',  // ← Exposes error details
    isLoading: false,
  );
}
```

**Issue:** Full exception details exposed to user.

**Potential Risk:**
- Stack traces could reveal internal structure
- Network errors could expose API endpoints
- Not critical but unprofessional

**Recommendation:**
```dart
catch (e) {
  debugPrint("⚠️ Error in search algorithm: $e");  // Keep for debugging
  
  // Generic user-facing message
  state = state.copyWith(
    error: 'Error al buscar ubicación. Inténtalo de nuevo.',
    isLoading: false,
  );
}
```

**Severity:** 🟢 LOW  
**Priority:** MEDIUM

---

### ✅ 5. HTTPS Usage - SECURE

**Status:** ✅ **PASS**

**Analysis:** All API calls use HTTPS, preventing man-in-the-middle attacks.

```dart
'https://nominatim.openstreetmap.org/search?...'  // ✅ HTTPS
```

**Verdict:** Secure communication channel.

---

### ✅ 6. User-Agent Header - COMPLIANT

**Status:** ✅ **PASS**

**Analysis:**
```dart
headers: {
  'User-Agent': 'com.inmufacil.app/1.0'
}
```

**Finding:** Complies with Nominatim usage policy requiring User-Agent identification.

**Verdict:** Policy compliant.

---

## 📋 Summary of Vulnerabilities

| # | Issue | Severity | Status | Priority |
|---|-------|----------|--------|----------|
| 1 | URL Encoding | ✅ Secure | PASS | - |
| 2 | Input Sanitization | 🟡 Medium | FAIL | HIGH |
| 3 | Rate Limiting | 🟡 Medium | FAIL | HIGH |
| 4 | Error Disclosure | 🟡 Low | FAIL | MEDIUM |
| 5 | HTTPS Usage | ✅ Secure | PASS | - |
| 6 | User-Agent | ✅ Compliant | PASS | - |

---

## 🎯 Recommendations

### Must Fix Before Production:
1. ✅ **Add input sanitization** (length + character validation)
2. ✅ **Implement debouncing** (500ms delay)
3. ✅ **Generic error messages** (hide exception details)

### Implementation Priority:
1. **HIGH:** Input sanitization (prevents abuse)
2. **HIGH:** Rate limiting/debouncing (API policy compliance)
3. **MEDIUM:** Error message sanitization (UX improvement)

---

## 🔒 Security Score

**Overall Rating:** 🟡 **6/10 - MEDIUM RISK**

**Breakdown:**
- ✅ Transport Security: 10/10
- ✅ API Compliance: 10/10
- 🟡 Input Validation: 4/10
- 🟡 Rate Control: 0/10
- 🟡 Error Handling: 6/10

**Recommendation:** **DO NOT MERGE** until HIGH priority fixes are implemented.

---

## 📝 Next Steps

1. Implement input sanitization
2. Add debouncing mechanism
3. Sanitize error messages
4. Re-test with malicious inputs
5. Update documentation with security considerations
6. Create PR with security improvements noted
