# ADR 013: Refinamiento de Contratos y Cuestionario Dinámico

**Fecha:** 2026-01-31
**Estado:** Propuesto
**Decisores:** @Architect, @Jules, @Shield

## Contexto
El usuario ha proporcionado un modelo de contrato más completo que incluye cláusulas específicas (Cuerpo Cierto, Fondos Extranjeros, Estado Físico). El modelo actual de "Arras Básico" es insuficiente. Necesitamos un sistema para "entrevistar" a las partes y generar un contrato a medida.

## Análisis del Modelo Aportado
El contrato OCR revela cláusulas críticas:
1.  **Cuerpo Cierto:** Venta por objeto, no por medida.
2.  **Origen de Fondos:** Cláusula de protección ante bloqueos bancarios por AML (Anti-Money Laundering) para extranjeros.
3.  **Estado del Inmueble:** Obligación de mantenimiento y conocimiento del estado actual.
4.  **Gastos:** Desglose específico de Community Fees.

## Decisión

### 1. Modelo de Datos
Añadiremos una columna `contract_data` (Tipo TEXT/JSON) a la tabla `offers`. No crearemos una tabla nueva para evitar sobre-ingeniería, ya que los datos son específicos del ciclo de vida de la oferta.

```python
# En PropertyOffer
contract_data = Column(JSON, nullable=True) 
# Estructura JSON:
# {
#   "is_cuerpo_cierto": true,
#   "has_foreign_funds": false,
#   "community_fees_monthly": 50.0,
#   "include_furniture": false,
#   "delivery_condition": "As is",
#   "max_deed_date": "2026-05-01"
# }
```

### 2. Cuestionario (API)
Implementaremos un endpoint `PUT /contracts/offers/{id}/details` que actúe como "Asistente Legal".
Este endpoint recibirá las respuestas del cuestionario y actualizará `contract_data`.

### 3. Generador Dinámico
`ContractGenerator` dejará de ser estático. Se refactorizará para componer el PDF bloque a bloque:
- `_add_header()`
- `_add_reunidos()`
- `_add_manifestan()` (Incluyendo cláusulas condicionales)
- `_add_estipulan()` (Incluyendo cláusulas condicionales)

## Consecuencias
*   **Positivas:** Contratos mucho más robustos y adaptados a la realidad.
*   **Negativas:** Mayor complejidad en el Generador PDF (lógica condicional de altura de página, saltos de línea, etc.).

## Plan de Acción
1.  Actualizar Schema DB (`PropertyOffer`).
2.  Crear Schema Pydantic `ContractDetails`.
3.  Implementar Endpoint de Cuestionario.
4.  Refactorizar `ContractGenerator`.
