"""
PropertyViewLog — Registro de visualizaciones unicas por usuario/IP.
Permite contabilizar el alcance real del anuncio en el Dashboard del Vendedor.
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Index
from sqlalchemy.sql import func
from .base import Base


class PropertyViewLog(Base):
    __tablename__ = "property_view_logs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    property_id = Column(
        Integer,
        ForeignKey("properties.id", ondelete="CASCADE"),
        nullable=False,
    )
    # NULL si es un visitante anonimo
    viewer_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    # Hash de IP para visitantes anonimos (SHA-256 truncado, no PII directa)
    ip_hash = Column(String(16), nullable=True)
    viewed_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    __table_args__ = (
        # Un usuario registrado cuenta una sola vez por propiedad
        Index("ix_view_log_property_viewer", "property_id", "viewer_id"),
        Index("ix_view_log_property_ip", "property_id", "ip_hash"),
    )
