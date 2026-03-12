"""
Pydantic schemas para el Centro de Notificaciones.

@Shield: Ningun campo de PII de otros usuarios se expone aqui.
         El user_id se resuelve siempre desde el token JWT del request.
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    """Schema de salida para una notificacion individual."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    body: str
    notification_type: str
    is_read: bool
    deep_link: Optional[str] = None
    offer_id: Optional[int] = None
    urgency_type: Optional[str] = None
    created_at: datetime
    sent_at: Optional[datetime] = None


class NotificationListResponse(BaseModel):
    """Respuesta paginada del historial de notificaciones."""

    items: list[NotificationResponse]
    total: int
    unread_count: int


class UrgentActionPayload(BaseModel):
    """Representacion de una accion urgente serializada desde Flutter."""

    offer_id: str
    property_title: str
    urgency_type: str           # Valor del enum UrgentActionType en Dart
    label: str
    route: str                  # Deep-link GoRouter (ej: "/offers/42/arras")


class SyncNotificationsRequest(BaseModel):
    """
    Payload para sincronizar notificaciones desde el estado actual de las ofertas.
    El frontend envia la lista de acciones urgentes calculadas por el urgencyProvider.
    """

    urgent_actions: list[UrgentActionPayload]


class RegisterFcmTokenRequest(BaseModel):
    """Registrar o actualizar el token FCM del dispositivo del usuario."""

    fcm_token: str


class MarkReadResponse(BaseModel):
    """Confirmacion de marcado como leido."""

    id: int
    is_read: bool
