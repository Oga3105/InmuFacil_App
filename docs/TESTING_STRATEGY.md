# Testing Strategy

Estrategia de pruebas mantenida por **@Jules** para garantizar robustez y QA estricto previo a Pull Request.

---

## Principios

- **TDD Red/Green/Refactor** — test primero, implementacion minima, refactor limpio
- **Sin tests = PR rechazado** (gate de merge non-negotiable)
- **Cobertura != calidad** — asserts significativos, no solo ejecucion de codigo
- **Sin tests flaky** — si aparece uno, se marca `skip` con justificacion o se corrige inmediatamente

---

## Backend (FastAPI / Pytest)

### Ubicacion
```
backend/tests/
├── conftest.py          # Fixtures compartidas (DB test, auth headers, client)
├── test_auth_*.py       # Autenticacion, MFA, Google OAuth
├── test_properties_*.py # CRUD propiedades, filtros, paginacion
├── test_offers_*.py     # Flujo de ofertas, contraofertas
├── test_kyc_*.py        # Verificacion de identidad
└── test_*.py            # Un archivo por modulo/comportamiento
```

### Tipos de test

| Tipo | Descripcion | Dependencias mockeadas |
|---|---|---|
| Unit | Logica de negocio aislada | DB, servicios externos, email |
| Integration | Endpoint real + DB de test | Servicios externos (Gemini, SMTP) |
| E2E | Flujo completo (registro → login → accion) | Nada (usa DB de test real) |

### Herramientas

- **pytest** + **pytest-asyncio** — runner principal
- **pytest-mock** / **unittest.mock** — mocking de dependencias externas
- **httpx AsyncClient / TestClient** — cliente HTTP para tests de endpoints
- **freezegun** — mockeo de `datetime.now()` en logica temporal
- **pytest-cov** — cobertura de codigo

### Cobertura minima

```bash
pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

**Umbral:** 80% de cobertura. CI falla si no se alcanza.

### Estrategia de BD de test

- DB separada o rollback por transaccion con `pytest-asyncio`
- Fixtures en `conftest.py` — no duplicar setup entre archivos
- Nunca usar la DB de desarrollo/produccion en tests

### Nomenclatura

```
test_<modulo>_<comportamiento>.py
test_auth_google_login_invalid_token.py
test_properties_create_missing_price.py
```

### Ejemplo de test de endpoint

```python
@pytest.mark.asyncio
async def test_contact_message_rate_limit(async_client, auth_headers):
    # Arrange: enviar 3 mensajes (maximo permitido)
    payload = {"subject": "Test", "message": "Mensaje de prueba larga"}
    for _ in range(3):
        resp = await async_client.post("/api/v1/contact/message", json=payload, headers=auth_headers)
        assert resp.status_code == 200

    # Act: el 4to debe ser rechazado
    resp = await async_client.post("/api/v1/contact/message", json=payload, headers=auth_headers)

    # Assert
    assert resp.status_code == 429
```

---

## Frontend (Flutter / Dart)

### Ubicacion

```
frontend/test/
├── unit/
│   ├── providers/       # Riverpod providers aislados (ProviderContainer)
│   └── formatters/      # CurrencyInputFormatter, etc.
├── widget/
│   ├── auth/            # LoginScreen, RegisterScreen
│   ├── home/            # HomeScreen states
│   └── common/          # Widgets reutilizables
└── integration/         # Flujos completos con WidgetTester
```

### Tipos de test

| Tipo | Descripcion | Framework |
|---|---|---|
| Unit | Providers Riverpod, repositorios, casos de uso | `flutter_test` + `mocktail` |
| Widget | Renderizado de componentes, estados (loading, error, data) | `flutter_test` |
| Integration | Flujo completo de pantalla | `flutter_test` con `WidgetTester` |

### Herramientas

- **flutter_test** — framework nativo de Flutter
- **mockito** / **mocktail** — mocking de repositorios y servicios
- **ProviderContainer** con overrides — para testear providers Riverpod en aislamiento

### Cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Revisar el reporte HTML antes de abrir un PR.

### Mocking de providers Riverpod

```dart
// Testear un provider con override
final container = ProviderContainer(
  overrides: [
    authProvider.overrideWith(() => MockAuthNotifier()),
  ],
);
addTearDown(container.dispose);
```

### Ejemplo de widget test

```dart
testWidgets('ContactEmailDialog shows error on rate limit', (tester) async {
  // Arrange
  final mockClient = MockApiClient();
  when(() => mockClient.client.post(any(), data: any(named: 'data')))
      .thenThrow(DioException(response: Response(statusCode: 429, ...)));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(mockClient)],
      child: const MaterialApp(home: ContactEmailDialog()),
    ),
  );

  // Act
  await tester.tap(find.text('Enviar mensaje'));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Has alcanzado el límite de mensajes.'), findsOneWidget);
});
```

---

## Tests de Regresion

Ante cualquier bug detectado en produccion:

1. Escribir test que reproduce el bug (debe fallar — RED)
2. Corregir el bug (GREEN)
3. Verificar que el test pasa y que no hay regresiones

**Regresion detectada** (test que pasaba y ahora falla) = BLOQUEANTE. Detener y notificar al usuario.

---

## Tests lentos

Marcar tests de integracion lentos para excluirlos del ciclo rapido de desarrollo:

```python
@pytest.mark.slow
async def test_full_kyc_flow(): ...
```

```bash
# Excluir tests lentos en desarrollo
pytest -m "not slow"

# Incluir todos en CI
pytest
```

---

## CI/CD

Los tests se ejecutan automaticamente en GitHub Actions en cada push y PR:

```yaml
# .github/workflows/
- Backend: pytest --cov=src --cov-fail-under=80
- Frontend: flutter test --coverage
- Linting: ruff check . && flutter analyze
```

PR bloqueado si cualquier step falla.
