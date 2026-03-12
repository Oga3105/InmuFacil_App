"""
Servicio de Notificaciones Push (FCM) con degradacion elegante.

@Shield:   Las credenciales de Firebase se cargan SOLO desde variables de entorno.
           NUNCA hardcodeadas. Si no estan configuradas, el servicio continua
           sin enviar push (funcionalidad degradada, no error critico).
@Watcher:  Toda operacion FCM se registra en log para auditoria.
@Architect: Patron Singleton para el cliente Firebase Admin.
"""

import logging
import os
from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from backend.src.models.notification_log import NotificationLog
from backend.src.models.users import User

logger = logging.getLogger("inmufacil.notifications")


# ─── Etiquetas de notificacion por tipo de urgencia ─────────────────────────

_URGENCY_TITLES = {
    "verifyIdentity":   "Verifica tu identidad",
    "completeSolvency": "Completa tu solvencia",
    "reviewSolvency":   "Revisa la solvencia",
    "signArras":        "Firma el contrato de Arras",
    "confirmFein":      "Confirma tu FEIN bancaria",
    "confirmTasacion":  "Gestiona la tasacion",
    "notaryAppointment":"Cita notarial pendiente",
}


def _get_notification_title(urgency_type: str) -> str:
    return _URGENCY_TITLES.get(urgency_type, "Accion requerida")


def _build_notification_body(label: str, full_name: Optional[str]) -> str:
    """
    Aplica la copia oficial de notificacion del proyecto:
    "No detengas la operacion, [Nombre] esta esperando tu [Accion]".
    """
    name = full_name or "el otro interviniente"
    return f"No detengas la operacion, {name} esta esperando: {label}."


# ─── Firebase Admin (carga opcional) ────────────────────────────────────────

_firebase_app = None
_firebase_initialized = False


def _get_firebase_app():
    """
    Intenta inicializar Firebase Admin SDK una sola vez.
    Si las credenciales no estan disponibles, retorna None sin lanzar excepcion.
    """
    global _firebase_app, _firebase_initialized

    if _firebase_initialized:
        return _firebase_app

    _firebase_initialized = True
    credentials_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

    if not credentials_path:
        logger.info(
            "[FCM] FIREBASE_SERVICE_ACCOUNT_JSON no configurado. "
            "Push notifications desactivadas (modo degradado)."
        )
        return None

    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(credentials_path)
            _firebase_app = firebase_admin.initialize_app(cred)
            logger.info("[FCM] Firebase Admin SDK inicializado correctamente.")
        else:
            _firebase_app = firebase_admin.get_app()

    except Exception as exc:
        logger.warning(f"[FCM] No se pudo inicializar Firebase Admin: {exc}")
        _firebase_app = None

    return _firebase_app


def _send_fcm_push(fcm_token: str, title: str, body: str, deep_link: Optional[str]) -> bool:
    """
    Envia un mensaje push via FCM.
    Retorna True si el envio fue exitoso, False en caso contrario.
    """
    app = _get_firebase_app()
    if app is None:
        return False

    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={"deep_link": deep_link or ""},
            token=fcm_token,
        )
        response = messaging.send(message)
        logger.info(f"[FCM] Push enviado. Message ID: {response}")
        return True

    except Exception as exc:
        logger.warning(f"[FCM] Error al enviar push: {exc}")
        return False


# ─── Operacion principal: upsert + push ─────────────────────────────────────

def upsert_urgency_notification(
    db: Session,
    *,
    user_id: int,
    offer_id: Optional[int],
    urgency_type: str,
    label: str,
    route: str,
    other_party_name: Optional[str] = None,
) -> Optional[NotificationLog]:
    """
    Crea o ignora una notificacion de urgencia para el usuario dado.

    - Si ya existe una con (user_id, offer_id, urgency_type), no crea duplicado.
    - Si no existe, la persiste y envia el push si el usuario tiene fcm_token.

    Retorna el NotificationLog existente o nuevo, o None si el usuario no existe.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        logger.warning(f"[NOTIF] upsert_urgency_notification: user_id={user_id} no encontrado.")
        return None

    title = _get_notification_title(urgency_type)
    body = _build_notification_body(label, other_party_name)

    # Verificar si ya existe (deduplicacion)
    existing = db.query(NotificationLog).filter(
        NotificationLog.user_id == user_id,
        NotificationLog.offer_id == offer_id,
        NotificationLog.urgency_type == urgency_type,
    ).first()

    if existing:
        logger.debug(
            f"[NOTIF] Notificacion ya existe para "
            f"user={user_id} offer={offer_id} type={urgency_type}. Ignorado."
        )
        return existing

    # Crear nueva notificacion
    sent_at = None
    if user.fcm_token:
        pushed = _send_fcm_push(user.fcm_token, title, body, route)
        if pushed:
            sent_at = datetime.utcnow()

    notification = NotificationLog(
        user_id=user_id,
        title=title,
        body=body,
        notification_type="urgency",
        is_read=False,
        deep_link=route,
        offer_id=offer_id,
        urgency_type=urgency_type,
        sent_at=sent_at,
    )

    try:
        db.add(notification)
        db.commit()
        db.refresh(notification)
        logger.info(
            f"[NOTIF] Nueva notificacion creada: id={notification.id} "
            f"user={user_id} type={urgency_type}"
        )
        return notification

    except IntegrityError:
        db.rollback()
        logger.debug(
            f"[NOTIF] Race condition: notificacion ya existe "
            f"user={user_id} offer={offer_id} type={urgency_type}."
        )
        return db.query(NotificationLog).filter(
            NotificationLog.user_id == user_id,
            NotificationLog.offer_id == offer_id,
            NotificationLog.urgency_type == urgency_type,
        ).first()


def mark_notification_read(db: Session, notification_id: int, user_id: int) -> Optional[NotificationLog]:
    """
    Marca una notificacion como leida.
    Verifica que pertenece al usuario autenticado (@Shield ownership check).
    """
    notification = db.query(NotificationLog).filter(
        NotificationLog.id == notification_id,
        NotificationLog.user_id == user_id,
    ).first()

    if notification is None:
        return None

    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification


def mark_all_read(db: Session, user_id: int) -> int:
    """Marca todas las notificaciones del usuario como leidas. Retorna el numero de filas afectadas."""
    count = (
        db.query(NotificationLog)
        .filter(NotificationLog.user_id == user_id, NotificationLog.is_read == False)
        .update({"is_read": True})
    )
    db.commit()
    return count
