# ADR 014: Preparación Notarial y Dossier Seguro

## Estado
Aceptado

## Contexto
Para finalizar la compraventa, la documentación debe elevarse a público ante Notario.
El sistema actual (InmuFácil) protege la privacidad de los usuarios mediante redacción (tachado) de documentos.
Sin embargo, el Notario requiere los documentos **originales** y los datos **desencriptados** (Unmasked) para verificar identidades y preparar la escritura.

## Decisión
Implementar un **Módulo de Preparación Notarial (Hito 14)** que:

1.  **Gestiona Notarios:** Base de datos de notarios colaboradores.
2.  **Asigna Notarios:** Permite vincular un notario a una oferta firmada (`SIGNED`).
3.  **Protocolo de Des-anonimización (The Great Unmasking):**
    - Se crea un servicio `NotaryDossierService`.
    - Bajo demanda explicita (generación de dossier), el sistema recupera los documentos originales del **Vault**.
    - Se genera un paquete ZIP con:
        - Contrato de Arras Firmado.
        - Nota Simple.
        - Certificado Energético.
        - **DNI Vendedor (Desencriptado).**
        - **DNI Comprador (Desencriptado).**
        - **MANIFEST.txt:** Archivo de control con hashes SHA256 de todos los documentos para garantizar integridad.

## Consecuencias
### Positivas
- **Automatización:** Se reduce la fricción en el paso final.
- **Seguridad:** Los datos solo se desencriptan en el momento justo y se empaquetan en un ZIP seguro (idealmente efímero).
- **Control:** El `MANIFEST.txt` asegura que el notario recibe exactamente lo que el sistema generó.

### Negativas
- **Riesgo:** El ZIP contiene datos sensibles en claro. Debe protegerse estrictamente el acceso al endpoint de descarga.
- **Simulación:** En esta fase, el "Unmasking" es simulado (archivos dummy), ya que el Vault real requiere integración de claves maestras complejas.

## Implementación Técnica
- **Modelo:** `Notary`, `PropertyOffer.notary_id`.
- **Servicio:** `NotaryDossierService` con lógica de hash SHA256.
- **API:** `GET /notaries/dossier/{offer_id}`.
