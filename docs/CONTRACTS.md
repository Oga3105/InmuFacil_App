# Data Contracts

Definiciones de los modelos de datos compartidos fundamentales. Estos contratos dictan el contrato exacto entre las llamadas DTO del Frontend en Dart y los esquemas en Pydantic del Backend.

## Property (Propiedad)
- Identificadores (UUID)
- Metadatos base (precio, tamaño, ubicación)
- Modelos Satélites: `PropertyFeatures`, `PropertyLegal`, `PropertyEnvironment`, `PropertyFinancial`.

## User (Usuario)
- Roles: `SELLER`, `BUYER`, `FINANCIERO`, `ADMIN`.

## Offer (Oferta)
- Estados: `PENDING`, `ACCEPTED`, `REJECTED`, `EXPIRED`, `CANCELLED`.
