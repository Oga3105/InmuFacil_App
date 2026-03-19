"""
Gemini AI KYC Verification Service
====================================
Uses Google Gemini 2.0 Flash (free tier) to automatically verify KYC documents.

Flow:
  1. Receives file paths for front, back (optional) and selfie images.
  2. Sends all images in a single multimodal request to Gemini.
  3. Parses the structured JSON response.
  4. Returns a GeminiKYCResult with the decision and extracted data.

The caller (background task in routes/kyc.py) then writes the result
to the DB and updates User.dni_status.
"""

import base64
import json
import logging
import os
import re
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Result dataclass
# ---------------------------------------------------------------------------

@dataclass
class GeminiKYCResult:
    approved: bool                          # True → validado, False → rechazado
    confidence: float                       # 0.0 – 1.0
    reason: str                             # Human-readable explanation
    name: Optional[str] = None
    surname: Optional[str] = None
    doc_number: Optional[str] = None
    raw_response: str = ""


# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------

_SYSTEM_PROMPT = """
Eres un sistema experto en verificación de identidad KYC para España.
Se te proporcionan hasta 3 imágenes:
  - FRENTE del documento (DNI, NIE o pasaporte español)
  - REVERSO del documento (puede no estar presente)
  - SELFIE del solicitante

Tu tarea es:
1. Determinar si el documento parece auténtico y legible (no es una fotocopia borrosa,
   no está manipulado digitalmente, tiene los elementos de seguridad esperados).
2. Verificar que la fotografía del documento coincide razonablemente con la selfie.
3. Extraer los datos básicos del documento (nombre, apellidos, número).

Responde ÚNICAMENTE con un objeto JSON válido, sin texto adicional, con esta estructura exacta:

{
  "authentic": true,
  "face_match": true,
  "confidence": 0.92,
  "name": "JUAN",
  "surname": "GARCIA LOPEZ",
  "doc_number": "12345678Z",
  "reason": "Documento auténtico. Rostro coincide con alta confianza."
}

Reglas de puntuación para "confidence":
- 0.85–1.00 : todo correcto, aprueba automáticamente
- 0.60–0.84 : dudas menores, aprueba con advertencia
- 0.00–0.59 : rechazar (documento ilegible, cara no coincide, posible fraude)

Si alguna imagen no está disponible o es ilegible, refléjalo en "reason"
y baja la puntuación de confianza acordemente.
""".strip()


# ---------------------------------------------------------------------------
# Main service function
# ---------------------------------------------------------------------------

_OCR_PROMPT = """
Eres un sistema OCR especializado en documentos de identidad españoles.
Se te proporciona la imagen del FRENTE (o página de datos) de un documento de identidad.

Tu UNICA tarea es extraer el número del documento con la máxima precisión.

Formatos válidos según tipo:
- DNI/NIF: 8 dígitos seguidos de una letra mayúscula (ej: 12345678Z)
- NIE: letra X, Y o Z + 7 dígitos + letra mayúscula (ej: X1234567L)
- Pasaporte español: 3 letras + 6 dígitos (ej: PAA123456)

Responde ÚNICAMENTE con un objeto JSON válido, sin texto adicional:

{
  "doc_number": "12345678Z",
  "readable": true
}

Si la imagen no es legible o no puedes extraer el número con confianza, responde:

{
  "doc_number": null,
  "readable": false
}
""".strip()


def extract_doc_number_from_image(
    front_path: str,
    document_type: str = "dni",
) -> dict:
    """
    Lightweight synchronous OCR call to Gemini to extract only the document number.
    Used for the pre-selfie confirmation step.
    Returns: {"doc_number": str|None, "readable": bool}
    Never raises — errors return {"doc_number": None, "readable": False}.
    """
    try:
        from google import genai
        from google.genai import types
    except ImportError:
        logger.error("google-genai not installed.")
        return {"doc_number": None, "readable": False}

    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        logger.error("GEMINI_API_KEY not set")
        return {"doc_number": None, "readable": False}

    if not front_path or not os.path.exists(front_path):
        return {"doc_number": None, "readable": False}

    try:
        mime = _infer_mime(front_path)
        with open(front_path, "rb") as f:
            data = f.read()
    except Exception as e:
        logger.warning("Could not read front image for OCR: %s", e)
        return {"doc_number": None, "readable": False}

    contents = [
        _OCR_PROMPT,
        f"[Imagen: FRENTE del {document_type.upper()}]",
        types.Part.from_bytes(data=data, mime_type=mime),
    ]

    try:
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model="gemini-2.0-flash-lite",
            contents=contents,
        )
        raw = response.text or ""
    except Exception as e:
        err_str = str(e)
        is_quota = "429" in err_str or "RESOURCE_EXHAUSTED" in err_str or "quota" in err_str.lower()
        if is_quota:
            logger.warning("Gemini quota exceeded during OCR extraction.")
        else:
            logger.error("Gemini OCR error: %s", e)
        return {"doc_number": None, "readable": False}

    cleaned = re.sub(r"```(?:json)?", "", raw).strip()
    match = re.search(r"\{.*\}", cleaned, re.DOTALL)
    if not match:
        logger.warning("No JSON in OCR Gemini response: %s", raw[:200])
        return {"doc_number": None, "readable": False}

    try:
        result = json.loads(match.group())
        doc_number = result.get("doc_number") or None
        readable = bool(result.get("readable", False)) and doc_number is not None
        logger.info("[OCR] Extraction attempt — readable=%s (doc_number logged separately for audit)", readable)
        return {"doc_number": doc_number, "readable": readable}
    except json.JSONDecodeError as e:
        logger.warning("OCR JSON parse error: %s", e)
        return {"doc_number": None, "readable": False}


def verify_identity_with_gemini(
    front_path: Optional[str],
    back_path: Optional[str],
    selfie_path: Optional[str],
    document_type: str = "dni",
    approval_threshold: float = 0.60,
) -> GeminiKYCResult:
    """
    Calls Gemini 2.0 Flash multimodal API to verify KYC documents.

    Returns a GeminiKYCResult. Never raises — errors are captured and returned
    as a rejected result with the error description in `reason`.
    """
    try:
        from google import genai
        from google.genai import types
    except ImportError:
        logger.error("google-genai not installed. Run: pip install google-genai")
        return GeminiKYCResult(
            approved=False,
            confidence=0.0,
            reason="Servicio de IA no disponible (paquete no instalado).",
        )

    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        logger.error("GEMINI_API_KEY not set in environment")
        return GeminiKYCResult(
            approved=False,
            confidence=0.0,
            reason="API key de Gemini no configurada.",
        )

    client = genai.Client(api_key=api_key)

    # Build contents list
    contents: list = [_SYSTEM_PROMPT]
    image_labels = []

    for label, path in [("FRENTE", front_path), ("REVERSO", back_path), ("SELFIE", selfie_path)]:
        if path and os.path.exists(path):
            try:
                mime = _infer_mime(path)
                with open(path, "rb") as f:
                    data = f.read()
                contents.append(f"[Imagen: {label} del {document_type.upper()}]")
                contents.append(types.Part.from_bytes(data=data, mime_type=mime))
                image_labels.append(label)
            except Exception as e:
                logger.warning("Could not read image %s: %s", path, e)

    if not image_labels:
        return GeminiKYCResult(
            approved=False,
            confidence=0.0,
            reason="No se pudieron cargar las imágenes para verificación.",
        )

    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash-lite",
            contents=contents,
        )
        raw = response.text or ""
    except Exception as e:
        logger.error("Gemini API error: %s", e)
        err_str = str(e)
        is_quota = (
            "429" in err_str
            or "RESOURCE_EXHAUSTED" in err_str
            or "quota" in err_str.lower()
        )
        is_model_not_found = (
            "NOT_FOUND" in err_str
            or ("404" in err_str and "NOT_FOUND" in err_str)
        )
        if is_quota:
            return GeminiKYCResult(
                approved=False,
                confidence=0.0,
                reason="__QUOTA_EXCEEDED__",
            )
        if is_model_not_found:
            logger.critical(
                "Gemini model not found. Check the model name in gemini_kyc_service.py. "
                "Error: %s", e
            )
            return GeminiKYCResult(
                approved=False,
                confidence=0.0,
                reason="__QUOTA_EXCEEDED__",
            )
        return GeminiKYCResult(
            approved=False,
            confidence=0.0,
            reason=f"Error al contactar con el servicio de IA: {e}",
        )

    return _parse_response(raw, approval_threshold)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _infer_mime(path: str) -> str:
    ext = os.path.splitext(path)[1].lower()
    return {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(ext, "image/jpeg")


def _parse_response(raw: str, threshold: float) -> GeminiKYCResult:
    """Extract JSON from Gemini response and build GeminiKYCResult."""
    # Strip markdown code fences if present
    cleaned = re.sub(r"```(?:json)?", "", raw).strip()

    # Find the JSON object
    match = re.search(r"\{.*\}", cleaned, re.DOTALL)
    if not match:
        logger.warning("No JSON found in Gemini response: %s", raw[:200])
        return GeminiKYCResult(
            approved=False,
            confidence=0.0,
            reason="Respuesta inesperada del servicio de IA.",
            raw_response=raw,
        )

    try:
        data = json.loads(match.group())
    except json.JSONDecodeError as e:
        logger.warning("JSON parse error: %s — raw: %s", e, raw[:200])
        return GeminiKYCResult(
            approved=False,
            confidence=0.0,
            reason="No se pudo interpretar la respuesta de IA.",
            raw_response=raw,
        )

    confidence = float(data.get("confidence", 0.0))
    approved = confidence >= threshold and bool(data.get("authentic", False))

    return GeminiKYCResult(
        approved=approved,
        confidence=confidence,
        reason=data.get("reason", ""),
        name=data.get("name"),
        surname=data.get("surname"),
        doc_number=data.get("doc_number"),
        raw_response=raw,
    )
