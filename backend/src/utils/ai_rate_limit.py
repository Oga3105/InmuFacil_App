"""
@Shield - AI Rate Limiter (Server-Side)

Aplica limites por feature y un techo global diario por usuario autenticado.
Detecta patrones de burst y dispara alertas a alerta@inmufacil.com de forma
asincrona (fire-and-forget) sin bloquear la respuesta 429 al cliente.

Uso en cualquier endpoint de IA:
    await check_ai_rate_limit(current_user.id, "market_price", db, request.client.host)
"""
from __future__ import annotations

import asyncio
import logging
import time
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Dict, List

from fastapi import HTTPException
from sqlalchemy.orm import Session

from backend.src.models.ai_usage_log import AiUsageLog

logger = logging.getLogger("inmufacil.ai_rate_limit")

# ---------------------------------------------------------------------------
# Limites por feature (llamadas permitidas en ventana de 24h)
# Deben coincidir con los dailyLimit definidos en frontend/lib/core/services/ai_types.dart
# ---------------------------------------------------------------------------

FEATURE_LIMITS: dict[str, int] = {
    "property_desc":        5,
    "comfort_index":        3,
    "market_price":         5,
    "legal_guide":          4,
    "nota_simple":          3,
    "solvency_check":       3,
    "price_validator":      5,
    "market_gap":           3,
    "neighborhood_twins":   3,
    "urban_growth":         3,
    "arras_contract":       2,
    "kyc_biometrics":       3,
    "ai_generate":          10,
}

# Techo global independiente de la feature
GLOBAL_DAILY_LIMIT = 20

# ---------------------------------------------------------------------------
# Burst tracker en memoria
# Detecta >5 llamadas totales de IA en 60 segundos (patron de ataque o bot).
# Se resetea al reiniciar el proceso — aceptable para TFM.
# En produccion con multiples workers usar Redis.
# ---------------------------------------------------------------------------

_BURST_WINDOW_SECONDS = 60
_BURST_THRESHOLD = 5  # llamadas en la ventana para considerar burst

_burst_tracker: Dict[int, List[float]] = defaultdict(list)


def _record_burst_and_check(user_id: int) -> bool:
    """
    Registra la llamada en el tracker de burst.
    Retorna True si se ha superado el umbral (alerta necesaria).
    No bloquea: el burst solo dispara alerta, no rechaza la request.
    """
    now = time.monotonic()
    window_start = now - _BURST_WINDOW_SECONDS
    calls = _burst_tracker[user_id]
    # Limpiar entradas antiguas
    calls[:] = [t for t in calls if t > window_start]
    calls.append(now)
    return len(calls) > _BURST_THRESHOLD


# ---------------------------------------------------------------------------
# Funcion principal
# ---------------------------------------------------------------------------

async def check_ai_rate_limit(
    user_id: int,
    feature: str,
    db: Session,
    ip: str = "unknown",
) -> None:
    """
    Verifica los limites de uso de IA para un usuario autenticado.

    Orden de verificacion:
    1. Limite por feature en 24h -> 429 + alerta email
    2. Limite global diario en 24h -> 429 + alerta email
    3. Registro de la llamada en ai_usage_log
    4. Deteccion de burst -> alerta email (no bloquea)

    Raises:
        HTTPException 429 si alguno de los limites numericos se supera.
    """
    cutoff = datetime.utcnow() - timedelta(hours=24)

    # -- 1. Check por feature --
    feature_count: int = (
        db.query(AiUsageLog)
        .filter(
            AiUsageLog.user_id == user_id,
            AiUsageLog.feature == feature,
            AiUsageLog.called_at >= cutoff,
        )
        .count()
    )

    limit = FEATURE_LIMITS.get(feature, 3)
    if feature_count >= limit:
        logger.warning(
            "[AI_RATE] LIMIT_REACHED user_id=%s feature=%s count=%s limit=%s ip=%s",
            user_id, feature, feature_count, limit, ip,
        )
        asyncio.create_task(
            _fire_alert(
                user_id=user_id,
                feature=feature,
                count=feature_count,
                limit=limit,
                ip=ip,
                alert_type="feature_limit",
            )
        )
        raise HTTPException(
            status_code=429,
            detail=(
                f"Has alcanzado el limite diario para '{feature}' "
                f"({limit} llamadas/24h). Intentalo manana."
            ),
        )

    # -- 2. Check global --
    global_count: int = (
        db.query(AiUsageLog)
        .filter(
            AiUsageLog.user_id == user_id,
            AiUsageLog.called_at >= cutoff,
        )
        .count()
    )

    if global_count >= GLOBAL_DAILY_LIMIT:
        logger.warning(
            "[AI_RATE] GLOBAL_LIMIT user_id=%s global_count=%s limit=%s ip=%s",
            user_id, global_count, GLOBAL_DAILY_LIMIT, ip,
        )
        asyncio.create_task(
            _fire_alert(
                user_id=user_id,
                feature=feature,
                count=global_count,
                limit=GLOBAL_DAILY_LIMIT,
                ip=ip,
                alert_type="global_limit",
            )
        )
        raise HTTPException(
            status_code=429,
            detail=(
                f"Has alcanzado el limite diario global de IA "
                f"({GLOBAL_DAILY_LIMIT} llamadas/24h). Intentalo manana."
            ),
        )

    # -- 3. Registrar llamada --
    db.add(AiUsageLog(user_id=user_id, feature=feature, ip_address=ip))
    db.commit()

    # -- 4. Burst detection (no bloquea, solo alerta) --
    if _record_burst_and_check(user_id):
        logger.warning(
            "[AI_BURST] user_id=%s burst_count=%s threshold=%s window=%ss ip=%s",
            user_id, len(_burst_tracker[user_id]), _BURST_THRESHOLD,
            _BURST_WINDOW_SECONDS, ip,
        )
        asyncio.create_task(
            _fire_alert(
                user_id=user_id,
                feature=feature,
                count=len(_burst_tracker[user_id]),
                limit=_BURST_THRESHOLD,
                ip=ip,
                alert_type="burst",
            )
        )


# ---------------------------------------------------------------------------
# Alerta email (fire-and-forget)
# ---------------------------------------------------------------------------

async def _fire_alert(
    user_id: int,
    feature: str,
    count: int,
    limit: int,
    ip: str,
    alert_type: str,
) -> None:
    """
    Envia alerta de abuso a alerta@inmufacil.com de forma asincrona.
    Si el envio falla, solo se loguea — nunca bloquea la respuesta al cliente.
    """
    try:
        from backend.src.services.email_service import send_ai_abuse_alert_email
        await send_ai_abuse_alert_email(
            user_id=user_id,
            feature=feature,
            count=count,
            limit=limit,
            ip=ip,
            alert_type=alert_type,
        )
    except Exception as exc:
        logger.error("[AI_RATE] Alert email failed (non-blocking): %r", exc)
