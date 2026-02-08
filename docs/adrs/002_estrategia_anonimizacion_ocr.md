# ADR 002: Estrategia de Anonimización con OCR

**Estado:** Aceptado  
**Fecha:** 2026-01-26  
**Autores:** @Jules, @Shield  
**Reemplaza:** Enfoque de coordenadas geométricas fijas

## Contexto

El sistema debe redactar (ocultar) datos sensibles en documentos de identidad (DNI, NIE, TIE, Pasaporte) antes de almacenarlos. El enfoque inicial usaba coordenadas geométricas fijas basadas en porcentajes de la imagen.

### Problemas del Enfoque Geométrico

1. **Variabilidad de Layouts:**
   - DNI 3.0 (sepia): IDESP en centro (40-65% × 45-60%)
   - DNI 4.0 (moderno): NUM SOPORT en centro-derecha (55-85% × 20-35%)
   - TIE (extranjeros): Número en esquina superior derecha (65-100% × 0-20%)

2. **Riesgo de Sobre-Redacción:**
   - Coordenadas fijas podían tapar el rostro accidentalmente
   - Documentos rotados o con márgenes variables fallaban

3. **Falta de Adaptabilidad:**
   - Nuevos formatos de documentos requerían calibración manual
   - No distinguía entre etiquetas y valores

## Decisión

Migrar a **detección semántica basada en OCR + Regex** con las siguientes fases:

### Sistema de 6 Fases

1. **OCR Text Extraction** - EasyOCR lee todo el texto con bounding boxes
2. **Critical Pattern Matching** - Regex detecta DNI, NIE, SOPORTE, etc.
3. **Aggressive NUM SOPORT** - Expansión de área (200% ancho, 150% alto)
4. **Context-Based Redaction** - Detecta etiquetas y redacta valores adyacentes
5. **Signature Redaction** - Busca keywords FIRMA/VALIDEZ
6. **Universal MRZ Cleaning** - Detecta y redacta Machine Readable Zone

### Patrones Regex Implementados

```python
patterns_critical = {
    'DNI/NIF': r'\b\d{8}[A-Z]\b',
    'NIE': r'\b[XYZ]\d{7}[A-Z]\b',
    'SOPORTE_DNI': r'\b[A-Z]{3}\s*\d{6}\b',  # Flexible spacing
    'SOPORTE_NIE': r'\bE\s*\d{8}\b',
    'SOPORTE_ORPHAN': r'\b[A-Z0-9]{9}\b',
    'PASSPORT': r'\b[A-Z]{2,3}\d{6,7}\b',
}
```

### Redacción Agresiva NUM SOPORT

Para garantizar captura del número de soporte:
- Detecta label "NUM SOPORT"
- Expande área de redacción 200% a la derecha, 150% abajo
- No depende de OCR del número en sí

## Consecuencias

### Positivas
- ✅ **Precisión quirúrgica:** Solo redacta valores, no etiquetas
- ✅ **Adaptabilidad:** Funciona con documentos rotados o con márgenes
- ✅ **Extensibilidad:** Nuevos patrones se añaden fácilmente
- ✅ **Seguridad:** Redacción agresiva garantiza cobertura
- ✅ **Trazabilidad:** Logs muestran qué se redactó y por qué

### Negativas
- ⚠️ **Dependencia pesada:** EasyOCR ~500MB con modelos
- ⚠️ **Tiempo de procesamiento:** +2-3s por documento en primera ejecución
- ⚠️ **Precisión OCR:** Documentos de baja calidad pueden fallar
- ⚠️ **Costo computacional:** Mayor uso de CPU vs coordenadas fijas

### Mitigaciones
- Lazy loading del OCR reader (solo se carga cuando se necesita)
- Caché del modelo en memoria para requests subsecuentes
- Fallback a redacción geométrica si OCR falla completamente

## Alternativas Consideradas

1. **Tesseract OCR**
   - Rechazado: Menor precisión con español, requiere configuración compleja

2. **Template Matching (OpenCV)**
   - Rechazado: Requiere templates para cada variante de documento

3. **Machine Learning (YOLO/Detectron)**
   - Rechazado: Overhead de entrenamiento, dataset requerido

## Implementación

### Commits Clave
- `d5f0301` - Initial OCR-based semantic redaction
- `632f8a4` - Regex 'Search and Destroy' pattern system
- `e5b1981` - Enhanced support detection with flexible spacing
- `a9b0972` - Aggressive NUM SOPORT area redaction

### Archivos Modificados
- `backend/services/kyc_service.py` - Core redaction logic
- `requirements.txt` - Added easyocr dependency

## Validación

Sistema validado con:
- ✅ DNI 3.0 (formato sepia)
- ✅ DNI 4.0 (formato moderno)
- ✅ NIE (extranjeros)
- ✅ TIE (permiso de residencia)

**Estado:** OPERATIVO - Código congelado para Hito 2

## Referencias

- [EasyOCR Documentation](https://github.com/JaidedAI/EasyOCR)
- [Spanish ID Document Specifications](https://www.dnielectronico.es/)
- Informe Técnico de Identidad (interno)
