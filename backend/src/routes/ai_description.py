"""
AI Description Route — Generacion de descripcion comercial con Gemini.

Endpoints:
  POST /properties/generate-description   Genera descripcion persuasiva para un inmueble
"""
from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

from backend.src.models import User
from backend.src.services.gemini_service import call_with_fallback, get_client
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/properties", tags=["AI Description"])
logger = logging.getLogger(__name__)

# Validate that google-genai is importable at startup so errors are caught early
_genai_available = False
try:
    from google import genai as _genai_check  # noqa: F401
    _genai_available = True
except Exception as _e:
    logger.error(
        "google-genai package not importable — AI description will be unavailable. "
        "Rebuild the backend Docker image: docker-compose build --no-cache backend. "
        "Error: %s", _e
    )

# Keep types import available for multimodal content building
try:
    from google.genai import types as _genai_types  # noqa: F401
except Exception:
    _genai_types = None  # type: ignore[assignment]


class DescriptionResponse(BaseModel):
    description: str
    generated_at: str


@router.post("/generate-description", response_model=DescriptionResponse)
async def generate_property_description(
    property_data: str = Form(...),
    images: List[UploadFile] = File(default=[]),
    current_user: User = Depends(get_current_active_user),
):
    """
    Genera una descripcion comercial profesional para un inmueble usando Gemini 2.0 Flash.
    Acepta datos tecnicos del inmueble como JSON y hasta 5 imagenes para analisis multimodal.
    """
    if not _genai_available:
        raise HTTPException(
            status_code=503,
            detail="Servicio de IA no disponible. El servidor necesita ser reiniciado con la imagen actualizada.",
        )

    try:
        from google.genai import types as genai_types
    except Exception:
        raise HTTPException(
            status_code=503,
            detail="Servicio de IA no disponible. Contacta con soporte.",
        )

    try:
        client = get_client()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    try:
        data = json.loads(property_data)
    except (json.JSONDecodeError, ValueError):
        raise HTTPException(status_code=422, detail="property_data JSON invalido.")

    # Build amenities list
    amenities: list[str] = []
    if data.get("has_pool"):
        amenities.append("piscina comunitaria")
    if data.get("has_garage"):
        amenities.append("plaza de garaje incluida")
    if data.get("has_terrace"):
        amenities.append("terraza privada")
    if data.get("has_garden"):
        amenities.append("jardin privado")
    if data.get("has_lift"):
        amenities.append("ascensor")
    if data.get("has_ac"):
        amenities.append("aire acondicionado")
    if data.get("has_heating"):
        amenities.append("calefaccion central")
    if data.get("has_exterior"):
        amenities.append("orientacion exterior")
    if data.get("has_storage"):
        amenities.append("trastero")
    if data.get("has_wardrobes"):
        amenities.append("armarios empotrados")

    price: int = data.get("price", 0)
    surface: float = data.get("surface_area", 0)
    bedrooms: int = data.get("bedrooms", 0)
    bathrooms: int = data.get("bathrooms", 0)
    city: str = data.get("city", "")
    province: str = data.get("province", "")
    property_type: str = data.get("property_type", "inmueble")
    energy_cert: str | None = data.get("energy_certification")
    draft: str = (data.get("draft_description") or "").strip()
    title: str = (data.get("title") or "").strip()

    location_str = city
    if province and province != city:
        location_str = f"{city}, {province}"

    valid_images = [img for img in images if img.content_type and img.content_type.startswith("image/")]
    has_images = len(valid_images) > 0

    prompt = f"""Eres un consultor inmobiliario senior especializado en redaccion de anuncios \
de venta de alto impacto para el mercado espanol.

Genera una descripcion comercial profesional para este inmueble. La descripcion debe ser \
persuasiva, detallada y orientada exclusivamente a la adquisicion del activo inmobiliario.

DATOS DEL INMUEBLE:
- Tipo de propiedad: {property_type}
- Precio de venta: {price:,} EUR
- Superficie: {surface} m2
- Dormitorios: {bedrooms}
- Banos: {bathrooms}
- Ubicacion: {location_str if location_str else 'no especificada'}
- Extras: {', '.join(amenities) if amenities else 'sin extras destacables'}
{f'- Certificacion energetica: {energy_cert}' if energy_cert else ''}
{f'- Titulo del anuncio: {title}' if title else ''}
{f'- Borrador del vendedor (tener en cuenta pero mejorar): {draft}' if draft else ''}

{'Analiza visualmente las imagenes adjuntas para detectar: calidades de acabado, luminosidad natural, amplitud de los espacios, estado de conservacion y elementos arquitectonicos diferenciadores. Incorpora estos detalles visuales en la descripcion.' if has_images else ''}

INSTRUCCIONES DE REDACCION:
1. VALOR DEL ACTIVO: argumentar por que el precio de {price:,} EUR es competitivo y justificado en el mercado actual.
2. ESTILO DE VIDA: ventajas de la ubicacion{' y luz natural detectada en las fotos' if has_images else ''}, calidad de vida, conectividad.
3. DETALLE TECNICO: descripcion impecable de metros, distribucion, estancias y calidades.
4. Tono: profesional, serio, de alta confianza. Sin emojis. Sin exclamaciones banales.
5. Longitud: entre 200 y 380 palabras.
6. Prohibido mencionar: alquiler, rentabilidad por arrendamiento, retorno de inversion.
7. Escribir en espanol peninsular. Sin anglicismos innecesarios.
8. No incluir titulos, encabezados ni puntos de lista. Solo parrafos corridos.

Genera UNICAMENTE el texto de la descripcion."""

    try:
        contents: list = [prompt]

        # Attach up to 5 images for multimodal analysis
        for img_file in valid_images[:5]:
            img_bytes = await img_file.read()
            if img_bytes:
                contents.append(
                    genai_types.Part.from_bytes(
                        data=img_bytes,
                        mime_type=img_file.content_type or "image/jpeg",
                    )
                )

        description, _model_used = call_with_fallback(
            client,
            contents=contents,
            preferred_model="gemini-2.0-flash",
        )
        if not description:
            raise HTTPException(
                status_code=503,
                detail="La IA no pudo generar una descripcion. Intentalo de nuevo.",
            )

        return DescriptionResponse(
            description=description,
            generated_at=datetime.now(timezone.utc).isoformat(),
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.error("Gemini description generation error: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="Error al generar la descripcion con IA. Intentalo de nuevo.",
        )
