# ADR 018: Integracion de IA con Gemini (Google Generative AI)

**Estado:** Aceptado
**Fecha:** 2026-03-22
**Autores:** @Architect, @Shield

---

## Contexto

InmuFacil necesita capacidades de inteligencia artificial para varios casos de uso:
1. **Descripcion automatica de propiedades**: Generar texto de marketing a partir de caracteristicas tecnicas
2. **Verificacion KYC**: Analizar documentos de identidad (DNI, NIE, Pasaporte) para extraer y validar datos
3. **Analisis de contratos propios**: El usuario puede subir un contrato PDF para que la IA identifique clausulas de riesgo

La plataforma ya tenia acceso a la API de Google (necesaria para Google OAuth) y el equipo tenia experiencia con el ecosistema Google, lo que facilitaba la integracion.

---

## Decision

Adoptar **Google Gemini** (via `google-genai >= 1.0`) como proveedor principal de IA para todos los casos de uso.

### Caso 1: Descripcion de Propiedades (ai_description / ai_generate)

- El usuario completa los datos tecnicos de la propiedad (tipo, m2, habitaciones, estado, zona)
- El backend construye un prompt estructurado y llama a Gemini Flash/Pro
- Gemini devuelve una descripcion en el idioma seleccionado, lista para publicar
- El endpoint es `POST /ai/description`

### Caso 2: Verificacion KYC con Gemini Vision

- El usuario sube una foto de su DNI/NIE/Pasaporte
- El backend recibe la imagen (multipart), la valida con MIME check, y la envia a Gemini Vision
- Gemini Vision extrae: numero de documento, nombre, fecha nacimiento, fecha expiracion
- El sistema cruza los datos extraidos con los datos declarados por el usuario
- Los datos sensibles se cifran con AES-256-GCM antes de persistir

### Caso 3: Analisis de Contratos (Analisis de Riesgo)

- El usuario sube un PDF/Word de su propio contrato de compraventa
- El backend extrae el texto (PyPDF2 / OCR) y lo envia a Gemini con un prompt de analisis legal
- Gemini identifica clausulas de riesgo (penalizaciones desproporcionadas, clausulas abusivas, etc.)
- El resultado es una lista de alertas con descripcion y nivel de severidad

### Configuracion

```python
# En .env
GEMINI_API_KEY=AIza...

# En el servicio
from google.genai import Client
client = Client(api_key=os.getenv("GEMINI_API_KEY"))
```

### Gestion del Consentimiento

Dado que el uso de IA implica procesamiento de datos personales (RGPD), todo uso de Gemini que involucre datos del usuario requiere consentimiento previo explícito. Ver ADR 019.

---

## Consecuencias

### Positivas
- Modelo unico para todos los casos de uso (menos integraciones que mantener)
- Gemini Vision es de alto rendimiento para analisis de documentos
- Precios competitivos y escalables por token
- La API es REST estandar, facil de mockear en tests

### Negativas
- **Vendor lock-in con Google**: Mitigado con la arquitectura hexagonal — los servicios de IA son reemplazables
- **Latencia**: Las llamadas a Gemini pueden tardar 2-5 segundos. Los endpoints de IA deben manejarse con indicadores de carga en el frontend
- **Costes en produccion**: Monitorizar uso de tokens para evitar sorpresas en facturacion
- **Privacidad**: Los datos enviados a Gemini deben estar anonimizados o tener consentimiento explicito del usuario (RGPD Art. 6.1.a)

---

## Alternativas Consideradas

1. **OpenAI GPT-4o Vision**
   - Considerado: Excelente para analisis de documentos
   - No seleccionado: Mayor coste y el proyecto ya usa credenciales Google

2. **Tesseract OCR (local)**
   - Considerado: Sin coste, privacidad total
   - No seleccionado: Menor precision en documentos de baja calidad, sin capacidad de razonamiento

3. **AWS Textract**
   - Rechazado: Introduce un tercer cloud provider en el stack
