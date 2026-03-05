"""
@Jules — Test suite for Chat Service

Tests:
  1. CensorshipFilter.sanitize()
     - Spanish mobile numbers (6xx, 7xx) — with and without +34 prefix
     - International numbers
     - Email addresses
     - Clean text passes through unchanged
     - Multiple patterns in one message

  2. CensorshipFilter.contains_sensitive()
     - Returns True when PII detected
     - Returns False for clean text

  3. ConnectionManager
     - broadcast() skips dead sockets gracefully
     - connection_count() reflects connected/disconnected state
"""

import asyncio
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from backend.src.services.chat_service import CensorshipFilter, ConnectionManager


# ── CensorshipFilter tests ────────────────────────────────────────────────────

class TestCensorshipFilter:

    def test_spanish_mobile_6xx_censored(self):
        text = "Llamame al 612 345 678 para acordar la visita"
        result = CensorshipFilter.sanitize(text)
        assert "612 345 678" not in result
        assert "[DATO CENSURADO" in result

    def test_spanish_mobile_with_prefix_censored(self):
        text = "Mi numero es +34 666111222"
        result = CensorshipFilter.sanitize(text)
        assert "666111222" not in result
        assert "[DATO CENSURADO" in result

    def test_spanish_mobile_7xx_censored(self):
        text = "Contactame en 712345678"
        result = CensorshipFilter.sanitize(text)
        assert "712345678" not in result
        assert "[DATO CENSURADO" in result

    def test_email_censored(self):
        text = "Escribe a juan.garcia@gmail.com para los papeles"
        result = CensorshipFilter.sanitize(text)
        assert "juan.garcia@gmail.com" not in result
        assert "[DATO CENSURADO" in result

    def test_clean_text_unchanged(self):
        text = "Estoy interesado en la propiedad. Podemos hablar por aqui?"
        result = CensorshipFilter.sanitize(text)
        assert result == text

    def test_multiple_patterns_in_message(self):
        text = "Soy Ana (ana@mail.es), mi movil es 698765432"
        result = CensorshipFilter.sanitize(text)
        assert "ana@mail.es" not in result
        assert "698765432" not in result
        assert result.count("[DATO CENSURADO") == 2

    def test_contains_sensitive_true_for_phone(self):
        assert CensorshipFilter.contains_sensitive("Llamame al 634567890") is True

    def test_contains_sensitive_true_for_email(self):
        assert CensorshipFilter.contains_sensitive("Email: test@test.com") is True

    def test_contains_sensitive_false_for_clean_text(self):
        assert CensorshipFilter.contains_sensitive("Nos vemos el lunes a las 10") is False

    def test_property_price_not_censored(self):
        # Ensure "350.000" (price format) is not treated as a phone number
        text = "El precio es 350.000 euros, muy razonable"
        result = CensorshipFilter.sanitize(text)
        assert result == text

    def test_postal_code_not_censored(self):
        text = "La propiedad esta en el CP 28001"
        result = CensorshipFilter.sanitize(text)
        assert result == text


# ── ConnectionManager tests ───────────────────────────────────────────────────

class TestConnectionManager:

    def test_connection_count_increments_on_connect(self):
        manager = ConnectionManager()
        offer_id = 42

        ws1 = AsyncMock()
        ws2 = AsyncMock()

        async def run():
            await manager.connect(offer_id, ws1)
            await manager.connect(offer_id, ws2)
            return manager.connection_count(offer_id)

        count = asyncio.get_event_loop().run_until_complete(run())
        assert count == 2

    def test_connection_count_decrements_on_disconnect(self):
        manager = ConnectionManager()
        offer_id = 7

        ws = AsyncMock()

        async def run():
            await manager.connect(offer_id, ws)
            manager.disconnect(offer_id, ws)
            return manager.connection_count(offer_id)

        count = asyncio.get_event_loop().run_until_complete(run())
        assert count == 0

    def test_broadcast_sends_to_all_connections(self):
        manager = ConnectionManager()
        offer_id = 1

        ws1 = AsyncMock()
        ws2 = AsyncMock()

        async def run():
            await manager.connect(offer_id, ws1)
            await manager.connect(offer_id, ws2)
            await manager.broadcast(offer_id, {"event": "message", "data": {"id": 1}})

        asyncio.get_event_loop().run_until_complete(run())

        ws1.send_json.assert_called_once()
        ws2.send_json.assert_called_once()

    def test_broadcast_removes_dead_connections(self):
        manager = ConnectionManager()
        offer_id = 99

        dead_ws = AsyncMock()
        dead_ws.send_json.side_effect = RuntimeError("connection closed")

        alive_ws = AsyncMock()

        async def run():
            await manager.connect(offer_id, dead_ws)
            await manager.connect(offer_id, alive_ws)
            await manager.broadcast(offer_id, {"event": "ping"})
            return manager.connection_count(offer_id)

        count = asyncio.get_event_loop().run_until_complete(run())
        # Dead connection was removed; alive remains
        assert count == 1
        alive_ws.send_json.assert_called_once()

    def test_broadcast_to_empty_room_is_noop(self):
        manager = ConnectionManager()
        # Should not raise even when no connections exist
        asyncio.get_event_loop().run_until_complete(
            manager.broadcast(9999, {"event": "ping"})
        )

    def test_disconnect_unknown_socket_is_noop(self):
        manager = ConnectionManager()
        ws = MagicMock()
        # Should not raise
        manager.disconnect(1234, ws)
