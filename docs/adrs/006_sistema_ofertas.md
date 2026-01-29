# ADR 006: Sistema de Ofertas Transparentes

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-29
*   **Decisores:** @Watcher, @Architect, @Jules

## Contexto
El comprador desea formalizar su interés mediante una oferta económica.
Debemos decidir cuánta información revelamos al vendedor y qué reglas rigen esta oferta.

## Decisión: Ofertas Transparentes
Se ha decidido implementar un modelo de **Ofertas Transparentes**.
El vendedor verá inmediatamente:
1.  **Monto** de la oferta.
2.  **Identidad** del comprador (Nombre y Perfil básico).
3.  **Condiciones** adjuntas (texto libre).

### Reglas de Negocio
1.  **No Auto-Ofertas:** Un propietario no puede ofertar por su propia casa.
2.  **Inmutabilidad:** Una vez enviada, la oferta no se edita. Se debe cancelar y crear una nueva.
3.  **Vigencia:** Las ofertas tienen fecha de caducidad (`valid_until`). El sistema las marcará como `EXPIRED` automáticamente (o mediante filtro) si pasa la fecha.
4.  **Estado Único:** Una propiedad puede tener múltiples ofertas activas de distintos compradores. Un comprador solo puede tener 1 oferta activa por propiedad.

## Estados de la Oferta (`OfferStatus`)
*   `PENDING`: Enviada, esperando respuesta.
*   `ACCEPTED`: Vendedor acepta negociar o cerrar.
*   `REJECTED`: Vendedor rechaza.
*   `EXPIRED`: Pasó la fecha límite.
*   `CANCELLED`: Comprador retira la oferta.

## Consecuencias
*   Fomenta la confianza entre partes al ser transparente.
*   Simplifica el modelo de datos (sin capas de anonimato temporal).
