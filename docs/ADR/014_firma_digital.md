# ADR 013: Infraestructura de Firma Digital (Mock Provider)

**Fecha:** 2026-02-01
**Estado:** Aceptado

## Contexto
Para completar el ciclo de compraventa (Hito 13), necesitamos permitir que compradores y vendedores firmen el Contrato de Arras.
En un entorno de producción real, esto requiere integración con un *Qualified Trust Service Provider* (QTSP) como Signaturit, DocuSign o Logalty para garantizar validez legal (eIDAS).
Sin embargo, para el desarrollo y demos, integrar un servicio de pago real es costoso e innecesario.

## Decisión
Implementar un sistema de firma digital basado en **Arquitectura Hexagonal (Ports & Adapters)**.

1.  **Interface (Port):** `SignatureProvider` define los métodos abstractos `request_signature` y `verify_signature`.
2.  **Mock (Adapter):** `MockSignatureProvider` implementa la interfaz simulando el comportamiento:
    - Genera tokens criptográficos de un solo uso.
    - Simula el envío de email (logging).
    - Provee un endpoint de "simulación de click" para desarrollo.
3.  **Seguridad:**
    - Tokens generados con `secrets.token_urlsafe` (Alta entropía).
    - Invalidación inmediata tras uso (One-time).
    - Trazabilidad de estados en base de datos (`SIGNING_PENDING` -> `SIGNED`).

## Consecuencias
### Positivas
- **Coste Cero:** No requerimos licencias de API externas durante dev/test.
- **Desacoplamiento:** Cambiar a Signaturit en PROD será tan simple como inyectar `SignaturitProvider` en el constructor de `SignatureService`.
- **Rapidez:** Tests E2E instantáneos sin depender de latencia de email real.

### Negativas
- **Validez Legal:** Las firmas generadas en este entorno NO tienen validez legal real, son solo para verificar el flujo de la aplicación.
- **Emails:** No se envían emails reales, el desarrollador debe mirar los logs para obtener el link de firma.
