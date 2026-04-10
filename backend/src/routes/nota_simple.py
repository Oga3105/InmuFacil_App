"""
Nota Simple Analyzer Route — AI-powered registry document analysis via Gemini Vision.

V55 — Nota Simple Analyzer

Endpoints:
  POST /ai/analyze-nota-simple   Analyze a Nota Simple document image with Gemini Flash Vision.
"""
from __future__ import annotations

import base64
import json
import logging
import os
import re

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.services.gemini_service import call_with_fallback, get_client
from backend.src.utils.ai_rate_limit import check_ai_rate_limit
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["Nota Simple"])
logger = logging.getLogger(__name__)

DISCLAIMER = (
    "Este analisis es una asistencia basada en IA. "
    "Debe ser validado por un profesional juridico antes de cualquier firma."
)

INVALIDITY_REASON_DEFAULT = (
    "Analisis incompleto: El documento no cumple los requisitos "
    "de legibilidad o vigencia"
)

SURFACE_DISCREPANCY_THRESHOLD = 0.05  # 5%


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class ChargeItem(BaseModel):
    charge_type: str = Field(
        ...,
        description='Tipo de carga: "financiera", "judicial" o "administrativa"',
    )
    description: str = Field(..., description="Descripcion textual de la carga")
    risk_level: str = Field(
        ...,
        description='Nivel de riesgo: "alto", "estandar" o "informativo"',
    )


class NotaSimpleRequest(BaseModel):
    document_base64: str = Field(
        ..., description="Documento en formato base64 (imagen o PDF renderizado)"
    )
    property_surface_m2: float = Field(
        ..., gt=0, description="Superficie del inmueble anunciada en el portal (m2)"
    )
    property_address: str = Field(
        ..., description="Direccion del inmueble para validacion cruzada"
    )


class NotaSimpleResponse(BaseModel):
    titular: str
    dni_partial: str
    surface_m2: float | None
    description: str
    charges: list[ChargeItem]
    surface_discrepancy_pct: float | None
    surface_alert: bool
    document_valid: bool
    invalidity_reason: str | None
    disclaimer: str


# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------

_EXTRACTION_PROMPT = """Analiza la siguiente imagen de una Nota Simple del Registro de la Propiedad espanol.

Extrae y devuelve un objeto JSON con exactamente esta estructura (sin texto adicional, solo el JSON):

{{
  "titular": "<nombre de pila + inicial del primer apellido + inicial del segundo apellido. Ej: Juan G. M.>",
  "dni_partial": "<ultimos 4 digitos del NIF/DNI del titular. Ej: 1234>",
  "surface_m2": <superficie en metros cuadrados como numero decimal, o null si no aparece>,
  "description": "<descripcion breve del inmueble segun el registro (tipo, ubicacion, ref catastral si aparece)>",
  "charges": [
    {{
      "charge_type": "<'financiera' si es hipoteca, prestamo o aval | 'judicial' si es embargo, anotacion preventiva, demanda | 'administrativa' si es servidumbre, afeccion fiscal, condicion resolutoria>",
      "description": "<texto literal o resumen de la carga>",
      "risk_level": "<'alto' para embargos y demandas judiciales | 'estandar' para hipotecas activas | 'informativo' para cargas administrativas o canceladas>"
    }}
  ],
  "document_valid": <true si el documento es una Nota Simple legible y vigente, false en caso contrario>,
  "invalidity_reason": "<razon de invalidez o null si el documento es valido>"
}}

Reglas de privacidad (GDPR):
- El campo "titular" debe anonimizar los apellidos a iniciales.
- El campo "dni_partial" debe contener SOLO los 4 ultimos digitos del NIF. Nunca el NIF completo.
- Si no se puede leer el NIF, devuelve "dni_partial": "****".

Si el documento es ilegible, incompleto, o no es una Nota Simple, devuelve document_valid: false y el motivo.
Si no hay cargas, devuelve "charges": [].

Inmueble de referencia para validacion cruzada: {address}
"""


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post("/analyze-nota-simple", response_model=NotaSimpleResponse)
async def analyze_nota_simple(
    request: NotaSimpleRequest,
    http_request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> NotaSimpleResponse:
    """
    Analyze a Nota Simple registry document using Gemini Flash Vision.

    Extracts: titular (anonymized), DNI partial (GDPR), surface, description,
    and a structured list of charges with risk classification.

    Cross-checks extracted surface against the advertised property surface.
    If the discrepancy exceeds 5%, raises a surface alert.
    """
    ip = http_request.client.host if http_request.client else "unknown"
    await check_ai_rate_limit(current_user.id, "nota_simple", db, ip)

    try:
        from google.genai import types as genai_types  # type: ignore[import]
    except ImportError:
        raise HTTPException(
            status_code=503,
            detail="Servicio de IA no disponible. Contacta con soporte.",
        )

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    # Validate base64 payload (basic check before sending to API)
    try:
        raw_bytes = base64.b64decode(request.document_base64, validate=True)
    except Exception:
        raise HTTPException(
            status_code=422,
            detail="El campo document_base64 no es un valor base64 valido.",
        )

    prompt_text = _EXTRACTION_PROMPT.format(address=request.property_address)

    try:
        image_part = genai_types.Part.from_bytes(
            data=raw_bytes,
            mime_type="image/jpeg",
        )
        text_part = genai_types.Part.from_text(text=prompt_text)

        raw_text, _ = call_with_fallback(
            client,
            contents=[genai_types.Content(parts=[image_part, text_part])],
            preferred_model="gemini-2.0-flash",
        )
    except HTTPException:
        raise
    except Exception as exc:
        error_repr = repr(exc)
        logger.error("[NotaSimple] Error calling Gemini Vision: %s", error_repr)
        raise HTTPException(
            status_code=500,
            detail="Error al analizar el documento. Intentalo de nuevo.",
        )

    # Parse JSON from Gemini response
    extracted = _parse_json_from_response(raw_text)

    if extracted is None:
        logger.warning(
            "[NotaSimple] Gemini returned unparseable response for address=%s",
            request.property_address,
        )
        return NotaSimpleResponse(
            titular="",
            dni_partial="****",
            surface_m2=None,
            description="",
            charges=[],
            surface_discrepancy_pct=None,
            surface_alert=False,
            document_valid=False,
            invalidity_reason=INVALIDITY_REASON_DEFAULT,
            disclaimer=DISCLAIMER,
        )

    document_valid: bool = bool(extracted.get("document_valid", False))
    invalidity_reason: str | None = extracted.get("invalidity_reason") or None

    if not document_valid and not invalidity_reason:
        invalidity_reason = INVALIDITY_REASON_DEFAULT

    # Parse charges
    raw_charges = extracted.get("charges") or []
    charges: list[ChargeItem] = []
    for c in raw_charges:
        if not isinstance(c, dict):
            continue
        charges.append(
            ChargeItem(
                charge_type=str(c.get("charge_type", "administrativa")),
                description=str(c.get("description", "")),
                risk_level=str(c.get("risk_level", "informativo")),
            )
        )

    # Surface cross-check
    surface_m2_raw = extracted.get("surface_m2")
    surface_m2: float | None = None
    surface_discrepancy_pct: float | None = None
    surface_alert = False

    if surface_m2_raw is not None:
        try:
            surface_m2 = float(surface_m2_raw)
            discrepancy = abs(surface_m2 - request.property_surface_m2) / request.property_surface_m2
            surface_discrepancy_pct = round(discrepancy * 100, 2)
            surface_alert = discrepancy > SURFACE_DISCREPANCY_THRESHOLD
        except (TypeError, ValueError, ZeroDivisionError):
            surface_m2 = None

    return NotaSimpleResponse(
        titular=str(extracted.get("titular", "")),
        dni_partial=str(extracted.get("dni_partial", "****")),
        surface_m2=surface_m2,
        description=str(extracted.get("description", "")),
        charges=charges,
        surface_discrepancy_pct=surface_discrepancy_pct,
        surface_alert=surface_alert,
        document_valid=document_valid,
        invalidity_reason=invalidity_reason,
        disclaimer=DISCLAIMER,
    )


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------


def _parse_json_from_response(text: str) -> dict | None:
    """
    Extract and parse the first JSON object from a Gemini text response.
    Gemini may wrap the JSON in markdown code fences.
    """
    # Strip markdown code fence if present
    fence_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if fence_match:
        text = fence_match.group(1)
    else:
        # Try to extract raw JSON object
        brace_match = re.search(r"\{.*\}", text, re.DOTALL)
        if brace_match:
            text = brace_match.group(0)

    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict):
            return parsed
    except json.JSONDecodeError:
        pass

    return None
