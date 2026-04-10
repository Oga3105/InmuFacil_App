"""
AI Usage Route — Estado de uso de IA del usuario autenticado.

Permite a Flutter sincronizar los contadores reales del servidor
en lugar de depender de SharedPreferences (bypasseable).

Endpoints:
  GET /ai/usage/me   Devuelve uso de las ultimas 24h por feature y global.
"""
from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models import User
from backend.src.models.ai_usage_log import AiUsageLog
from backend.src.utils.ai_rate_limit import FEATURE_LIMITS, GLOBAL_DAILY_LIMIT
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/ai", tags=["AI Usage"])


class FeatureUsage(BaseModel):
    used: int
    limit: int


class AiUsageResponse(BaseModel):
    global_used_24h: int
    global_limit_24h: int
    features: dict[str, FeatureUsage]


@router.get("/usage/me", response_model=AiUsageResponse)
async def get_my_ai_usage(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> AiUsageResponse:
    """
    Retorna el uso de IA del usuario autenticado en las ultimas 24 horas.

    La UI de Flutter usa este endpoint para mostrar contadores reales
    y bloquear llamadas antes de llegar al servidor cuando el limite se acerca.
    """
    cutoff = datetime.utcnow() - timedelta(hours=24)

    rows = (
        db.query(AiUsageLog.feature)
        .filter(
            AiUsageLog.user_id == current_user.id,
            AiUsageLog.called_at >= cutoff,
        )
        .all()
    )

    # Contar por feature
    counts: dict[str, int] = {}
    for (feature,) in rows:
        counts[feature] = counts.get(feature, 0) + 1

    global_used = len(rows)

    features: dict[str, FeatureUsage] = {
        key: FeatureUsage(used=counts.get(key, 0), limit=lim)
        for key, lim in FEATURE_LIMITS.items()
    }

    return AiUsageResponse(
        global_used_24h=global_used,
        global_limit_24h=GLOBAL_DAILY_LIMIT,
        features=features,
    )
