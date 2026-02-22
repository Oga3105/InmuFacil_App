# ADR 012: Motor de Generación de Contratos

**Fecha:** 2026-01-31
**Estado:** Aceptado
**Decisores:** @Architect, @DevOps, @Jules

## Contexto
Para el Hito 12, necesitamos generar borradores de contratos legales (inicialmente "Arras Penitenciales") en formato PDF de manera dinámica. Los datos deben provenir de la base de datos (Comprador, Vendedor, Inmueble, Oferta) y el documento debe ser profesional e inmutable una vez generado.

## Decisión
Hemos decidido utilizar la librería **ReportLab** para la generación de PDFs en Python.

### Detalles de Implementación:
1.  **Librería:** `reportlab` (Open Source Version).
2.  **Servicio:** `ContractGenerator` (Singleton/Static Service) que encapsula la lógica de maquetación.
3.  **Seguridad:**
    *   Endpoint protegido con `GET /contracts/arras/draft/{offer_id}`.
    *   Verificación estricta de roles: Solo Comprador y Vendedor de la oferta pueden descargar el borrador.
    *   Estado: Solo ofertas en estado `ACCEPTED`.
4.  **Modelo de Datos:**
    *   Se utiliza `PropertyOffer` como punto de entrada.
    *   Se han añadido relaciones explícitas en `PropertyOffer` para acceder a `Buyer` y `Property` de forma eficiente.
    *   Implementamos `get_current_user` en `auth.py` para resolver dependencias circulares y centralizar la autenticación.

## Alternativas Consideradas

*   **WeasyPrint:** Descartada por requerir dependencias de sistema (GTK) que complican el despliegue en entornos Windows/Serverless sin contenedores pesados.
*   **FPDF2:** Descartada por menor control tipográfico y características avanzadas en comparación con ReportLab.

## Consecuencias

*   **Positivas:**
    *   Generación rápida y ligera de PDFs.
    *   Sin dependencias externas pesadas.
    *   Control total sobre el posicionamiento de elementos (pixel-perfect).
*   **Negativas:**
    *   Curva de aprendizaje de ReportLab es más alta que HTML-to-PDF.
    *   Mantenimiento de plantillas es mediante código Python, no HTML/CSS.
