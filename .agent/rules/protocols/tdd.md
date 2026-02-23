# PROTOCOLO: TDD — Red / Green / Refactor

**Version:** 1.0
**Fecha:** 2026-02-23
**Responsable:** @Jules
**Trigger:** Cualquier cambio de codigo o nueva funcionalidad.

---

## GATE DE MERGE (NON-NEGOTIABLE)

Codigo sin tests asociados = PR rechazado automaticamente. Sin excepciones.

---

## CICLO OBLIGATORIO

Para toda nueva logica, seguir este ciclo en orden estricto:

```
1. RED:      Escribir el test. Verificar que FALLA por la razon correcta (no por error de sintaxis).
2. GREEN:    Escribir la implementacion MINIMA para que el test pase. Nada mas.
3. REFACTOR: Limpiar el codigo (nombres, duplicacion, estructura) sin romper los tests.
```

Nunca saltar al paso 2 sin haber ejecutado y verificado el paso 1.

---

## BACKEND (FastAPI / Python)

**Framework:** `pytest` + `pytest-mock` + `httpx` (AsyncClient / TestClient)
**Fixtures:** Compartidas en `conftest.py`. No duplicar setup entre archivos de test.
**Nomenclatura de archivos:** `test_<modulo>_<comportamiento>.py`
**Ubicacion:** `backend/tests/`

**Tipos de test:**
- **Unitario:** Logica de negocio aislada. Dependencias externas mockeadas.
- **Integracion:** Endpoint real + base de datos de test. Verificar contrato HTTP completo.
- **E2E:** Flujo de usuario completo (registro -> login -> accion).

**Cobertura minima:** 80%
**Comando de validacion:**
```bash
pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

**Estrategia de mocking:**
- Base de datos: usar DB de test separada o `pytest-asyncio` con rollback por transaccion.
- Servicios externos (email, storage): mockear con `pytest-mock` / `unittest.mock`.
- Tiempo: mockear con `freezegun` cuando la logica dependa de `datetime.now()`.

---

## FRONTEND (Flutter / Dart)

**Framework:** `flutter_test` + `mockito` + `mocktail`
**Nomenclatura de archivos:** `<widget_o_provider>_test.dart`
**Ubicacion:** `frontend/test/`

**Tipos de test:**
- **Unit:** Providers de Riverpod, repositorios, casos de uso. Sin widgets.
- **Widget:** Renderizado de componentes individuales. Verificar UI states (loading, error, data).
- **Integration:** Flujo completo de pantalla. Usar `flutter_test` con `WidgetTester`.

**Cobertura:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**Estrategia de mocking:**
- Repositorios: mockear con `mockito` o `mocktail`.
- Providers de Riverpod: usar `ProviderContainer` con overrides en tests.
- HTTP: interceptar con `dio_mock_interceptor` o mockear el repositorio directamente.

---

## REGLAS COMUNES

1. **Bug encontrado** -> escribir test de regresion que lo reproduce ANTES de corregir el bug.
2. **Regresion detectada** (test que pasaba y ahora falla) = BLOQUEANTE. Detener y notificar al usuario antes de continuar.
3. **Tests de integracion lentos** -> marcar con `@pytest.mark.slow` y excluirlos de la suite rapida de desarrollo.
4. **Sin tests flaky** (tests que fallan intermitentemente). Si aparece uno, corregirlo inmediatamente o marcarlo como `skip` con justificacion.
5. **Cobertura != calidad**. 80% de cobertura con asserts significativos, no con tests que solo ejecutan codigo sin verificar comportamiento.
