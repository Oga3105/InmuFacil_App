# ADR 007: Protocolo de Negociación Híbrido y Encriptación

*   **Estado:** Aceptado
*   **Fecha:** 2026-01-29
*   **Decisores:** @Watcher, @Architect, @Jules

## Contexto
Los usuarios necesitan negociar el precio y las condiciones. Un simple "Aceptar/Rechazar" es insuficiente.
Además, necesitan un canal de comunicación seguro para aclarar dudas sin salir de la plataforma.

## Decisión: Protocolo Híbrido

### 1. Protocolo Formal (La "Verdad Legal")
Los cambios en el acuerdo se registran en una entidad inmutable `OfferHistory`.
*   **Acciones:** `MAKE_OFFER`, `COUNTER_OFFER`, `ACCEPT`, `REJECT`.
*   **Regla:** Una contraoferta invalida el monto anterior y actualiza el estado de la oferta principal a `COUNTERED`.

### 2. Canal de Chat (La "Comunicación")
*   **Opcional:** Desactivado por defecto. El vendedor decide si abrir el chat.
*   **Privado:** 1-a-1 entre Vendedor y el dueño de la Oferta.
*   **Encriptado:** Los mensajes se almacenan cifrados en la base de datos (At-Rest Encryption) usando el módulo `backend.crypto`.

## Modelo de Datos

### OfferHistory
*   `offer_id`: FK.
*   `actor_id`: Quién hizo el cambio.
*   `action`: String (Enum).
*   `amount`: Nuevo monto (si aplica).
*   `timestamp`: Cuándo.

### OfferMessage
*   `offer_id`: FK.
*   `sender_id`: Quién envía.
*   `message_encrypted`: Texto cifrado.
*   `timestamp`: Cuándo.

## Seguridad (Defense in Depth)
*   **Encryption:** Uso de `Fernet` (Simétrico) para el contenido del mensaje.
*   **Access Control:** Un usuario solo puede leer mensajes de una oferta si es el Vendedor (Owner) o el Comprador (Buyer) de ESA oferta.
*   **Anti-Spam:** El comprador no puede iniciar el chat hasta que el vendedor lo habilite.

## Consecuencias
*   Aumenta la complejidad del router `offers.py`.
*   Garantiza privacidad total incluso ante dumps de base de datos.
