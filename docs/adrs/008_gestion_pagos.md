# ADR 008: Gestión de Pagos, Reservas e Idempotencia

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-29
*   **Decisores:** @Watcher, @Architect, @Jules

## Contexto
Los compradores deben poder bloquear una propiedad pagando una señal.
Esto introduce riesgos críticos:
1.  **Doble Venta:** Dos usuarios pagan a la vez.
2.  **Doble Cobro:** El usuario reintenta el pago por error de red.
3.  **Seguridad PCI:** No podemos tocar números de tarjeta reales.

## Decisión 1: Mock Payment Gateway
Para esta fase, NO integraremos Stripe real. Usaremos un servicio simulado.
*   **Input:** `token` (simulado, ej "tok_visa").
*   **Comportamiento:** Acepta "tok_visa", rechaza "tok_fail".
*   **Beneficio:** Permite probar todo el flujo transaccional sin credenciales bancarias.

## Decisión 2: Idempotencia estricta
El cliente (Frontend) DEBE generar un UUID único (`Idempotency-Key`) para cada intento de intención de reserva.
*   Si el backend recibe el mismo UUID, devuelve el resultado de la transacción original (incluso si falló) sin re-procesar el pago.
*   Esto previene cobros duplicados.

## Decisión 3: Bloqueo de Base de Datos
Para prevenir la doble venta (Race Condition):
*   Usaremos `SELECT ... FOR UPDATE` al verificar el estado de la propiedad antes de procesar el pago.
*   Si la propiedad ya está `RESERVED`, la segunda transacción falla inmediatamente.

## Modelo de Visibilidad
*   Estado `RESERVED`: La propiedad sigue pública por defecto (escaparate de éxito).
*   Flag `hide_when_reserved`: Si el propietario lo marca, la propiedad deja de salir en listados públicos (`GET /properties`).

## Consecuencias
*   Necesitamos gestionar estados intermedios de pago (`PENDING` -> `PAID`).
*   La búsqueda (`GET /properties`) se vuelve más compleja al tener que filtrar por status y configuración.
