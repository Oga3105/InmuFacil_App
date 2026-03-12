"""
NotificationLog model — Historial persistente de notificaciones push.

@Architect: Tabla de auditoria de notificaciones enviadas a cada usuario.
@Shield:    Constraint UNIQUE(user_id, offer_id, type) previene duplicados
            por la misma accion bloqueante en la misma oferta.
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from .base import Base


class NotificationLog(Base):
    """
    Registro historico de notificaciones enviadas y recibidas.
    Cada fila corresponde a un evento de notificacion unico por (user, offer, type).
    """

    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)

    # Destinatario
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Contenido
    title = Column(String(255), nullable=False)
    body = Column(String(1000), nullable=False)

    # Clasificacion
    # "urgency"  — accion bloqueante del motor de urgencias
    # "info"     — informacion no bloqueante (nueva visita agendada, etc.)
    # "system"   — avisos del sistema (mantenimiento, actualizaciones)
    notification_type = Column(String(32), nullable=False, default="urgency")

    # Estado de lectura
    is_read = Column(Boolean, nullable=False, default=False)

    # Deep-link para GoRouter v17 (ej: "/offers/42/arras")
    deep_link = Column(String(512), nullable=True)

    # Referencia a la oferta que origino la notificacion (nullable para avisos de sistema)
    offer_id = Column(Integer, ForeignKey("offers.id", ondelete="SET NULL"), nullable=True, index=True)

    # Tipo de accion urgente que origino la notificacion (ej: "signArras", "completeSolvency")
    # Junto con user_id y offer_id forma la clave de deduplicacion
    urgency_type = Column(String(64), nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)  # Cuando se envio el push (null si no aplica)

    # Relaciones
    user = relationship("User", back_populates="notifications")

    # Constraint de deduplicacion: un usuario no recibe la misma accion urgente
    # dos veces para la misma oferta sin que el estado haya cambiado.
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "offer_id",
            "urgency_type",
            name="uq_notification_user_offer_type",
        ),
    )

    def __repr__(self) -> str:
        return (
            f"<NotificationLog id={self.id} user={self.user_id} "
            f"type={self.notification_type} read={self.is_read}>"
        )
