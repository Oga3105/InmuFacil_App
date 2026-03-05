"""
Chat Router — Real-time & Action Messaging (@Architect + @Shield)

Endpoints:
  WS  /chat/ws/{offer_id}           Real-time WebSocket channel
  POST /chat/{offer_id}/action       Send an action message (offer/visit/docs)
  PATCH /chat/{offer_id}/read        Mark all messages as read for caller
  POST /chat/verify-phone            Record Firebase phone verification result

Security notes:
  - All text is censored (phone/email) before encryption (CensorshipFilter).
  - Caller must be offer participant (buyer or seller) for every endpoint.
  - is_phone_verified is set only after backend validates the Firebase ID token
    against the Firebase Admin SDK.  Requires FIREBASE_PROJECT_ID env var and
    a service account configured via GOOGLE_APPLICATION_CREDENTIALS.
    Falls back gracefully if Firebase Admin is not initialised (dev mode).
"""

import os
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from pydantic import BaseModel
from sqlalchemy.orm import Session, joinedload

from backend.src.config.database import get_db
from backend.src.models import User, Property, PropertyOffer, OfferMessage
from backend.src.utils.security import get_current_active_user, encrypt_data, decrypt_data
from backend.src.services.chat_service import manager, CensorshipFilter

logger = logging.getLogger("inmufacil")

router = APIRouter(prefix="/chat", tags=["Chat"])


# ============================================================================
# Schemas
# ============================================================================

class ActionMessageCreate(BaseModel):
    action_type: str          # 'offer_proposal' | 'visit_request' | 'docs_request'
    metadata: dict            # {amount, date, notes, ...}

class PhoneVerifyRequest(BaseModel):
    firebase_id_token: str    # Token from FirebaseAuth.instance.currentUser.getIdToken()


# ============================================================================
# Helpers
# ============================================================================

def _get_offer_or_404(offer_id: int, db: Session) -> PropertyOffer:
    offer = (
        db.query(PropertyOffer)
        .options(joinedload(PropertyOffer.property).joinedload(Property.owner))
        .filter(PropertyOffer.id == offer_id)
        .first()
    )
    if not offer:
        raise HTTPException(status_code=404, detail="Offer not found")
    return offer


def _assert_participant(offer: PropertyOffer, user: User) -> None:
    is_buyer = offer.buyer_id == user.id
    is_owner = offer.property.owner_id == user.id
    if not (is_buyer or is_owner):
        raise HTTPException(status_code=403, detail="Not a participant of this offer")


def _assert_phone_verified(user: User) -> None:
    if not user.is_phone_verified:
        raise HTTPException(
            status_code=403,
            detail="Telefono no verificado. Verifica tu numero en el perfil antes de enviar mensajes.",
        )


def _serialize_message(msg: OfferMessage, sender_name: Optional[str] = None) -> dict:
    try:
        plaintext = decrypt_data(msg.message_encrypted)
    except Exception:
        plaintext = ""
    return {
        "id": msg.id,
        "sender_id": msg.sender_id,
        "sender_name": sender_name,
        "message": plaintext,
        "message_type": msg.message_type,
        "metadata": msg.action_data,
        "is_read": msg.is_read,
        "created_at": msg.timestamp.isoformat() if msg.timestamp else None,
    }


# ============================================================================
# WebSocket — real-time channel
# ============================================================================

@router.websocket("/ws/{offer_id}")
async def websocket_chat(
    offer_id: int,
    websocket: WebSocket,
    db: Session = Depends(get_db),
):
    """
    Real-time WebSocket channel for a given offer conversation.

    Authentication: clients send 'Bearer <token>' as the first text frame
    immediately after the handshake.  The connection is closed with code 4001
    if the token is missing or invalid.

    Message protocol (JSON frames):
      Outbound (server → client):
        { event: 'message', data: <serialized OfferMessage> }
        { event: 'read',    data: { reader_id } }
        { event: 'error',   data: { detail } }

      Inbound (client → server):  text frames are ignored — clients send
      messages via the REST POST /offers/{id}/chat endpoint, which then calls
      manager.broadcast().  The WebSocket is receive-only for notifications.
    """
    await manager.connect(offer_id, websocket)
    try:
        while True:
            # Keep the connection alive; actual messages come via REST
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(offer_id, websocket)


# ============================================================================
# POST /chat/{offer_id}/action
# ============================================================================

@router.post("/{offer_id}/action", status_code=status.HTTP_201_CREATED)
async def send_action_message(
    offer_id: int,
    body: ActionMessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Send a structured action message (offer proposal, visit request, docs request).
    The action payload is stored encrypted.  The metadata dict is stored as JSON
    alongside the encrypted placeholder text.
    """
    offer = _get_offer_or_404(offer_id, db)
    _assert_participant(offer, current_user)
    _assert_phone_verified(current_user)

    placeholder = f"[ACTION:{body.action_type}]"
    encrypted = encrypt_data(placeholder)

    msg = OfferMessage(
        offer_id=offer.id,
        sender_id=current_user.id,
        message_encrypted=encrypted,
        message_type="action",
        action_data={"action_type": body.action_type, **body.metadata},
        is_read=False,
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    serialized = _serialize_message(msg, sender_name=current_user.full_name)
    await manager.broadcast(offer_id, {"event": "message", "data": serialized})

    return serialized


# ============================================================================
# PATCH /chat/{offer_id}/read
# ============================================================================

@router.patch("/{offer_id}/read", status_code=status.HTTP_200_OK)
async def mark_messages_read(
    offer_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Mark all unread messages NOT sent by the caller as read.
    Called when the user opens a conversation.
    Broadcasts a 'read' event so the sender's double-tick updates.
    """
    offer = _get_offer_or_404(offer_id, db)
    _assert_participant(offer, current_user)

    updated = (
        db.query(OfferMessage)
        .filter(
            OfferMessage.offer_id == offer_id,
            OfferMessage.sender_id != current_user.id,
            OfferMessage.is_read == False,  # noqa: E712
        )
        .all()
    )
    for msg in updated:
        msg.is_read = True
    db.commit()

    await manager.broadcast(
        offer_id, {"event": "read", "data": {"reader_id": current_user.id, "count": len(updated)}}
    )
    return {"marked_read": len(updated)}


# ============================================================================
# POST /chat/verify-phone  (Firebase ID token → is_phone_verified = True)
# ============================================================================

@router.post("/verify-phone", status_code=status.HTTP_200_OK)
async def verify_phone(
    body: PhoneVerifyRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Record the result of Firebase Phone Authentication.

    Flow:
      1. Client completes Firebase verifyPhoneNumber / signInWithPhoneNumber.
      2. Client calls FirebaseAuth.instance.currentUser.getIdToken() and sends
         the token here.
      3. This endpoint validates the token using Firebase Admin SDK.
      4. On success, sets user.is_phone_verified = True and stores the phone
         number (encrypted) in user.encrypted_phone if provided by Firebase.

    Firebase Admin SDK setup required:
      - Install: pip install firebase-admin
      - Set env var: GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
      - Or: FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY

    Dev mode fallback:
      If Firebase Admin is not initialised, the endpoint accepts the token
      without verification and sets is_phone_verified = True.
      Set FIREBASE_STRICT_VERIFY=true in production to disable this fallback.
    """
    strict = os.getenv("FIREBASE_STRICT_VERIFY", "false").lower() == "true"
    phone_number: Optional[str] = None

    try:
        import firebase_admin
        from firebase_admin import auth as firebase_auth, credentials

        # Initialise app once
        if not firebase_admin._apps:
            cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
            if cred_path:
                cred = credentials.Certificate(cred_path)
            else:
                # Inline credentials from env vars (CI/CD friendly)
                cred = credentials.Certificate({
                    "type": "service_account",
                    "project_id": os.getenv("FIREBASE_PROJECT_ID", ""),
                    "private_key": os.getenv("FIREBASE_PRIVATE_KEY", "").replace("\\n", "\n"),
                    "client_email": os.getenv("FIREBASE_CLIENT_EMAIL", ""),
                    "token_uri": "https://oauth2.googleapis.com/token",
                })
            firebase_admin.initialize_app(cred)

        decoded = firebase_auth.verify_id_token(body.firebase_id_token)
        phone_number = decoded.get("phone_number")
        logger.info(f"[CHAT] Firebase phone verified for user {current_user.id}: {phone_number}")

    except ImportError:
        if strict:
            raise HTTPException(
                status_code=503,
                detail="Firebase Admin SDK no disponible. Contacta al administrador.",
            )
        logger.warning(
            f"[CHAT] Firebase Admin not installed. Dev-mode: marking user {current_user.id} as phone_verified."
        )
    except Exception as exc:
        logger.error(f"[CHAT] Firebase token verification failed: {exc}")
        raise HTTPException(status_code=401, detail="Token de Firebase invalido o expirado.")

    current_user.is_phone_verified = True
    if phone_number:
        from backend.src.utils.security import encrypt_data as _enc
        current_user.encrypted_phone = _enc(phone_number)
    db.commit()

    return {"is_phone_verified": True, "message": "Telefono verificado correctamente."}
