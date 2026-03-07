"""
Chat Service (@Architect + @Shield)

ConnectionManager  — WebSocket session registry for real-time delivery.
                     Single-process, in-memory. For multi-worker deployments
                     replace with a Redis pub/sub backend (Fase 2).

CensorshipFilter   — GDPR-compliant text sanitizer.
                     Blocks Spanish phone numbers and email addresses before
                     encryption so raw PII never reaches the database.
                     Applied on EVERY message type (text and action).
"""

import re
import asyncio
from typing import Dict, List, Optional
from fastapi import WebSocket


# ============================================================================
# WebSocket Connection Manager
# ============================================================================

class ConnectionManager:
    """
    Manages active WebSocket connections keyed by offer_id.

    Lifecycle:
        connect()     -> accept handshake, register socket
        disconnect()  -> remove socket (called on close or send failure)
        broadcast()   -> push JSON payload to all sockets for an offer
        send_to()     -> push JSON payload to a single socket (private)
    """

    def __init__(self) -> None:
        self._connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, offer_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections.setdefault(offer_id, []).append(websocket)

    def disconnect(self, offer_id: int, websocket: WebSocket) -> None:
        bucket = self._connections.get(offer_id, [])
        if websocket in bucket:
            bucket.remove(websocket)

    async def broadcast(
        self,
        offer_id: int,
        payload: dict,
        exclude: Optional[WebSocket] = None,
    ) -> None:
        """Send payload to every connection in the offer room, except `exclude`."""
        dead: List[WebSocket] = []
        for ws in list(self._connections.get(offer_id, [])):
            if ws is exclude:
                continue
            try:
                await ws.send_json(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(offer_id, ws)

    def connection_count(self, offer_id: int) -> int:
        return len(self._connections.get(offer_id, []))


# Singleton — imported by routes/chat.py
manager = ConnectionManager()


# ============================================================================
# Censorship Filter  (@Shield — GDPR compliance)
# ============================================================================

class CensorshipFilter:
    """
    Strips contact-identifying patterns from message text before storage.

    Covered patterns:
      - Spanish mobile numbers: 6xx/7xx/8xx/9xx (with +34 / 0034 prefix)
      - International format numbers with country code
      - Email addresses (RFC 5321 subset)

    Applied in: routes/chat.py before encrypt_data()
    """

    _PHONE_ES = re.compile(
        r'(\+34|0034)?[\s\-\.]?[6789]\d{2}[\s\-\.]?\d{3}[\s\-\.]?\d{3}'
    )
    _PHONE_INTL = re.compile(
        r'\+\d{1,3}[\s\-]?\(?\d{1,4}\)?[\s\-]?\d{3,5}[\s\-]?\d{4,6}'
    )
    _EMAIL = re.compile(
        r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'
    )

    _REPLACEMENT = '[DATO CENSURADO - usa la plataforma para intercambiar informacion de contacto]'

    @classmethod
    def sanitize(cls, text: str) -> str:
        """Return text with all phone/email patterns replaced."""
        text = cls._PHONE_INTL.sub(cls._REPLACEMENT, text)
        text = cls._PHONE_ES.sub(cls._REPLACEMENT, text)
        text = cls._EMAIL.sub(cls._REPLACEMENT, text)
        return text

    @classmethod
    def contains_sensitive(cls, text: str) -> bool:
        """True if the text contains a pattern that would be censored."""
        return bool(
            cls._PHONE_ES.search(text)
            or cls._PHONE_INTL.search(text)
            or cls._EMAIL.search(text)
        )
