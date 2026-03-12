"""
Endpoints del Centro de Notificaciones.

@Shield: Todos los endpoints requieren autenticacion JWT.
         El user_id se extrae del token — el usuario solo accede a sus propias notificaciones.
@FrontendProxy: Contrato API definido en schemas/notifications.py
"""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.src.config.database import get_db
from backend.src.models.notification_log import NotificationLog
from backend.src.models.users import User
from backend.src.schemas.notifications import (
    NotificationListResponse,
    NotificationResponse,
    SyncNotificationsRequest,
    RegisterFcmTokenRequest,
    MarkReadResponse,
)
from backend.src.services.notification_service import (
    upsert_urgency_notification,
    mark_notification_read,
    mark_all_read,
)
from backend.src.utils.security import get_current_active_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])


# ─── GET /notifications ───────────────────────────────────────────────────────

@router.get(
    "",
    response_model=NotificationListResponse,
    summary="Historial de notificaciones del usuario autenticado",
)
def get_notifications(
    skip: int = 0,
    limit: int = 50,
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Retorna el historial de notificaciones del usuario ordenado de mas reciente a mas antiguo.
    Filtro opcional: unread_only=true para obtener solo las no leidas.
    """
    query = db.query(NotificationLog).filter(
        NotificationLog.user_id == current_user.id
    )

    if unread_only:
        query = query.filter(NotificationLog.is_read == False)

    total = query.count()
    unread_count = (
        db.query(NotificationLog)
        .filter(
            NotificationLog.user_id == current_user.id,
            NotificationLog.is_read == False,
        )
        .count()
    )

    items = (
        query.order_by(NotificationLog.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    return NotificationListResponse(
        items=[NotificationResponse.model_validate(n) for n in items],
        total=total,
        unread_count=unread_count,
    )


# ─── PATCH /notifications/{id}/read ──────────────────────────────────────────

@router.patch(
    "/{notification_id}/read",
    response_model=MarkReadResponse,
    summary="Marcar una notificacion como leida",
)
def read_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Marca la notificacion indicada como leida.
    @Shield: Solo el propietario de la notificacion puede marcarla.
    """
    notification = mark_notification_read(db, notification_id, current_user.id)

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notificacion no encontrada o no pertenece al usuario autenticado.",
        )

    return MarkReadResponse(id=notification.id, is_read=notification.is_read)


# ─── PATCH /notifications/read-all ───────────────────────────────────────────

@router.patch(
    "/read-all",
    summary="Marcar todas las notificaciones como leidas",
)
def read_all_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Marca todas las notificaciones no leidas del usuario como leidas."""
    count = mark_all_read(db, current_user.id)
    return {"marked_read": count}


# ─── POST /notifications/sync ─────────────────────────────────────────────────

@router.post(
    "/sync",
    response_model=NotificationListResponse,
    status_code=status.HTTP_200_OK,
    summary="Sincronizar notificaciones desde el estado actual de las ofertas",
)
def sync_notifications(
    payload: SyncNotificationsRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    El frontend envia la lista de acciones urgentes calculadas por el urgencyProvider.
    El backend persiste (upsert) cada accion como NotificationLog y envia el push
    si el dispositivo tiene token FCM registrado.

    Esta operacion es idempotente: llamarla multiples veces con el mismo estado
    no genera duplicados.
    """
    for action in payload.urgent_actions:
        offer_id_int: Optional[int] = None
        try:
            offer_id_int = int(action.offer_id)
        except (ValueError, TypeError):
            pass

        upsert_urgency_notification(
            db,
            user_id=current_user.id,
            offer_id=offer_id_int,
            urgency_type=action.urgency_type,
            label=action.label,
            route=action.route,
        )

    # Retornar historial actualizado
    return _fetch_notification_list(db, current_user.id)


# ─── POST /notifications/register-fcm-token ──────────────────────────────────

@router.post(
    "/register-fcm-token",
    status_code=status.HTTP_200_OK,
    summary="Registrar o actualizar el token FCM del dispositivo",
)
def register_fcm_token(
    payload: RegisterFcmTokenRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Almacena el token FCM del dispositivo del usuario para recibir push notifications.
    @Shield: El token es por usuario, no por sesion — actualiza el existente si ya habia uno.
    """
    current_user.fcm_token = payload.fcm_token
    db.commit()
    return {"status": "ok", "message": "Token FCM registrado correctamente."}


# ─── Helper privado ───────────────────────────────────────────────────────────

def _fetch_notification_list(db: Session, user_id: int) -> NotificationListResponse:
    items = (
        db.query(NotificationLog)
        .filter(NotificationLog.user_id == user_id)
        .order_by(NotificationLog.created_at.desc())
        .limit(50)
        .all()
    )
    total = db.query(NotificationLog).filter(NotificationLog.user_id == user_id).count()
    unread_count = (
        db.query(NotificationLog)
        .filter(NotificationLog.user_id == user_id, NotificationLog.is_read == False)
        .count()
    )
    return NotificationListResponse(
        items=[NotificationResponse.model_validate(n) for n in items],
        total=total,
        unread_count=unread_count,
    )
