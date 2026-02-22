# State Machines

Lógica de estados complejos que controlan el flujo de trabajo funcional en el backend.

## Flujo de Visitas (`VisitStatus`)
El ciclo principal de una cita.
1. `REQUESTED` -> Estado base cuando el comprador toma el slot de tiempo.
2. **Transiciones desde `REQUESTED`**:
   - -> `APPROVED` (Vendedor aprueba)
   - -> `REJECTED` (Vendedor rechaza)
   - -> `CANCELLED` (Cualquiera cancela)
3. **Transiciones post-aprobación** (Desde `APPROVED`):
   - -> `COMPLETED` (Solo marcable por Vendedor tras realizarla).
   - -> `NO_SHOW` (Ausencia del comprador, impacta reputación).
   - -> `CANCELLED` (Problema de fuerza mayor).

## Flujo de Ofertas (`OfferStatus`)
1. `PENDING` -> Oferta recién creada.
2. **Transiciones**:
   - -> `ACCEPTED` -> Si avanza, da comienzo al flujo de contratos (`SIGNING_PENDING` -> `SIGNED`).
   - -> `REJECTED`
   - -> `EXPIRED` -> Ofertas que superan su `valid_until`.
   - -> `CANCELLED` -> Si el comprador la retira prematuramente.

> Una contra-oferta registra en el Historial una acción `COUNTER_OFFER` e invalida la cabecera del monto base anterior.
