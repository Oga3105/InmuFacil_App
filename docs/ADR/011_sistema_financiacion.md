# ADR 011: Sistema de Financiación y Perfilado

## Estado
Aceptado

## Contexto
Para completar el ciclo de compraventa (Hito 11), es necesario integrar herramientas financieras que permitan al comprador evaluar su capacidad de endeudamiento y obtener ofertas hipotecarias preliminares.
Además, se requiere la figura de un experto humano ("El Financiero") que pueda asistir en este proceso.

## Decisión
Se ha decidido implementar un módulo de **Financiación Híbrido** que combina automoción y asesoramiento humano.

### 1. Modelado de Datos
*   **`MortgageProfile`**: Almacena datos sensibles de solvencia (Ingresos, Deudas, Ahorros, Edad, Tipo Contrato).
    *   *Seguridad:* Relación 1:1 con `User`. Acceso restringido al Propietario y al Consejero asignado.
*   **`MortgageSimulation`**: Histórico de simulaciones realizadas. Almacena un snapshot JSON de las ofertas recibidas para evitar inconsistencias si el algoritmo cambia.

### 2. Nuevo Rol: `FINANCIERO`
*   Se añade `UserType.FINANCIERO` al Enum de roles.
*   Se establece una relación reflexiva en `User` (`financial_advisor_id`) para permitir la asignación de un experto.

### 3. Integración Externa (Mock Strategy)
En lugar de depender de APIs reales (costosas/complejas en fase MVP), se implementa un **"Meta-Agregador Simulado"** en `FinancingService`.
*   **Fuentes Simuladas:** iAhorro (Broker Digital) y Bancos Tradicionales (Santander, BBVA).
*   **Lógica:** El servicio genera ofertas basándose en un "Solvency Score" interno (0-100) calculado a partir del perfil.

### 4. Scoring de Solvencia (Algoritmo Interno)
Se implementa un algoritmo determinista simple para el MVP:
*   Base: 50 puntos.
*   Bonificadores: Funcionario (+30), Indefinido (+20), Ingresos > 3k (+10).
*   Penalizadores: Temporal (-10), Ingresos < 1.2k (-10).
*   *Nota:* Este algoritmo es provisional y debe ser sustituido por un motor de riesgo real en producción.

## Consecuencias
*   **Positivas:** Permite demostrar el flujo completo de "Buscar -> Visitar -> Financiar -> Comprar" sin dependencias externas bloqueantes.
*   **Negativas:** Las ofertas no son vinculantes ni reales, lo que debe ser comunicado claramente al usuario (UI).
*   **Riesgos:** La acumulación de datos financieros sensibles (`MortgageProfile`) eleva el nivel de riesgo de seguridad, requiriendo auditorías de acceso estrictas (cumplidas por RLS en Router).
