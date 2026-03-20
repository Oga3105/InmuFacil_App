"""
@Shield - AI Consent Log Model (GDPR Art. 6.1.a / LOPDGDD Art. 7)

Registra cada consentimiento explícito del usuario para el uso de IA.
Proporciona trazabilidad completa para descarga de responsabilidad legal.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base


class AIConsentLog(Base):
    """
    Registro inmutable de consentimientos explícitos para uso de IA.

    Cada fila representa un consentimiento puntual: un usuario, una accion,
    un instante. Los registros NO se borran (derecho al olvido = anonimizacion,
    no borrado, para preservar la trazabilidad legal).
    """
    __tablename__ = "ai_consent_logs"

    id = Column(Integer, primary_key=True, index=True)

    # Titular del consentimiento
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # Descripcion de la accion autorizada
    action_type = Column(String(100), nullable=False)       # e.g. "property_description"
    action_label = Column(String(255), nullable=False)      # Texto human-readable mostrado al usuario
    data_categories = Column(Text, nullable=False)          # JSON array: categorias de datos enviados
    purpose = Column(Text, nullable=False)                  # Finalidad declarada al usuario
    ai_provider = Column(String(255), nullable=False)       # Nombre del proveedor IA externo

    # Version del texto de consentimiento (trazabilidad legal de cambios de policy)
    consent_text_version = Column(String(50), nullable=False, default="v1.0")

    # Timestamp del consentimiento (servidor, no cliente — no manipulable)
    consented_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Datos tecnicos de sesion (GDPR accountability — Art. 5.2)
    ip_address = Column(String(45), nullable=True)    # IPv4 (15) o IPv6 (39) + margen
    user_agent = Column(String(512), nullable=True)

    # Contexto adicional (puede ser null si la accion no es especifica de un inmueble)
    property_id = Column(String(50), nullable=True)

    # Relacion (solo lectura — sin cascade para preservar registros aunque el usuario se borre)
    user = relationship("User", foreign_keys=[user_id])
