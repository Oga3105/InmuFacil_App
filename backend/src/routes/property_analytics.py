"""
Property Analytics Routes — Metricas publicas de rendimiento del anuncio.

Endpoints:
  GET  /properties/{id}/analytics   Metricas del anuncio (publico)
  POST /properties/{id}/view        Registrar visualizacion (anonima o autenticada)
"""
from __future__ import annotations

import hashlib
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import Property, PropertyFavorite, PropertyViewLog
from backend.src.models.offers import PropertyOffer
from backend.src.utils.security import get_optional_current_user

router = APIRouter(prefix="/properties", tags=["Property Analytics"])
logger = logging.getLogger(__name__)

_ACTIVE_OFFER_STATUSES = ("pending", "counter_offer", "accepted", "signing_pending", "signed")


class PropertyAnalyticsResponse(BaseModel):
    views: int
    favorites: int
    offers: int


# ---------------------------------------------------------------------------
# GET /properties/{id}/analytics — Solo el propietario puede ver sus metricas
# ---------------------------------------------------------------------------

@router.get("/{property_id}/analytics", response_model=PropertyAnalyticsResponse)
def get_property_analytics(
    property_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Devuelve las metricas de rendimiento de un anuncio: visitas unicas,
    favoritos y ofertas activas. Publico para todos los usuarios.
    """
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Propiedad no encontrada.")

    views = (
        db.query(func.count(PropertyViewLog.id))
        .filter(PropertyViewLog.property_id == property_id)
        .scalar()
        or 0
    )

    favorites = (
        db.query(func.count(PropertyFavorite.id))
        .filter(PropertyFavorite.property_id == property_id)
        .scalar()
        or 0
    )

    offers = (
        db.query(func.count(PropertyOffer.id))
        .filter(
            PropertyOffer.property_id == property_id,
            PropertyOffer.status.in_(_ACTIVE_OFFER_STATUSES),
        )
        .scalar()
        or 0
    )

    return PropertyAnalyticsResponse(views=views, favorites=favorites, offers=offers)


# ---------------------------------------------------------------------------
# POST /properties/{id}/view — Registrar visita (publica, auth opcional)
# ---------------------------------------------------------------------------

@router.post("/{property_id}/view", status_code=status.HTTP_204_NO_CONTENT)
def log_property_view(
    property_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Registra una visualizacion unica del inmueble.
    Para usuarios autenticados: una entrada por (property_id, user_id).
    Para anonimos: una entrada por (property_id, ip_hash).
    No falla si la propiedad no existe (endpoint silencioso).
    """
    try:
        if current_user is not None:
            # Comprueba si ya existe registro para este usuario
            exists = (
                db.query(PropertyViewLog.id)
                .filter(
                    PropertyViewLog.property_id == property_id,
                    PropertyViewLog.viewer_id == current_user.id,
                )
                .first()
            )
            if not exists:
                log = PropertyViewLog(
                    property_id=property_id,
                    viewer_id=current_user.id,
                )
                db.add(log)
                db.commit()
        else:
            client_ip = request.client.host if request.client else "unknown"
            ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:16]
            exists = (
                db.query(PropertyViewLog.id)
                .filter(
                    PropertyViewLog.property_id == property_id,
                    PropertyViewLog.ip_hash == ip_hash,
                )
                .first()
            )
            if not exists:
                log = PropertyViewLog(
                    property_id=property_id,
                    ip_hash=ip_hash,
                )
                db.add(log)
                db.commit()
    except Exception as exc:
        logger.warning("View log error for property %s: %s", property_id, exc)
        db.rollback()
