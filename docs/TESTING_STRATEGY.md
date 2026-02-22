# Testing Strategy

Estrategia de pruebas mantenida por el Agente **@Jules** para garantizar robustez y un QA estricto previo a PULL REQUEST.

## Frontend (Flutter)
- **Unit Tests**: Empleamos `mockito` para emular Repositories y Providers, testeando Notifiers exhaustivamente sin tocar el servidor o UI.
- **Widget Tests**: Usado para componentes del UI reutilizables (Botones, Inputs, Cards). Verificamos renderizados en distintas resoluciones para prevenir casos comunes de `RenderFlex overflow`.
- **Integration Tests (End-to-End)**: Ocasional para flujos de registro, publicación y firma de contratos en *Device Simulators*.

## Backend (FastAPI / Pytest)
- **Unit Tests**: Mockeo de componentes transaccionales, se aísla la lógica en Services (ejemplo: algoritmo de recomendación y score financiero).
- **Integration Tests**: Levantado de una Test Database (Idealmente una base de datos efímera tipo `sqlite` in-memory pero usando la sintaxis de sqlalchemy estándar del modelo local).
- **Cobertura Exigida**: Todo nuevo Endpoint en FastAPI debe incluir testcase al menos para código 200 (éxito) y un código 400x base.
