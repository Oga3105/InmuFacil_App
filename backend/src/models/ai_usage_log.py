"""
AiUsageLog — Registro de llamadas a IA por usuario (server-side rate limiting).

Tabla de solo insercion/lectura. No almacena contenido de las llamadas (RGPD-safe).
Cada fila = una llamada realizada por un usuario autenticado a un endpoint de IA.
La ventana de consulta es siempre 24h hacia atras (rolling window).
"""
from sqlalchemy import Column, DateTime, Index, Integer, String, ForeignKey
from sqlalchemy.sql import func

from .base import Base


class AiUsageLog(Base):
    __tablename__ = "ai_usage_log"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    # Feature key — debe coincidir con las claves de FEATURE_LIMITS en ai_rate_limit.py
    feature = Column(String(50), nullable=False)
    # Timestamp del servidor (no del cliente)
    called_at = Column(DateTime, server_default=func.now(), nullable=False)
    # IP para trazabilidad de abusos (nullable — algunos proxies no la exponen)
    ip_address = Column(String(45), nullable=True)

    __table_args__ = (
        # Indice compuesto para la consulta de rate-check: O(log n)
        Index("ix_ai_usage_log_user_feature_date", "user_id", "feature", "called_at"),
    )
