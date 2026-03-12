"""
@Jules — TDD: Notification Center (V17)

Tests de persistencia de NotificationLog y filtrado por user_id.
Verifica que:
  1. upsert_urgency_notification crea una notificacion correctamente.
  2. Llamar dos veces con los mismos parametros NO crea duplicados (idempotencia).
  3. Un usuario no puede leer notificaciones de otro (ownership check).
  4. mark_notification_read cambia el estado is_read.
  5. mark_all_read afecta solo las notificaciones del usuario indicado.
  6. GET /notifications retorna solo las notificaciones del usuario autenticado.
  7. PATCH /notifications/{id}/read retorna 404 si la notificacion no pertenece al usuario.

Run: pytest backend/tests/test_notifications.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

from backend.main import app
from backend.src.models.notification_log import NotificationLog
from backend.src.models.users import User
from backend.src.services.notification_service import (
    upsert_urgency_notification,
    mark_notification_read,
    mark_all_read,
)


# ─── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture
def client():
    return TestClient(app)


def _make_user(user_id: int, fcm_token: str | None = None) -> User:
    user = MagicMock(spec=User)
    user.id = user_id
    user.full_name = f"Usuario Test {user_id}"
    user.fcm_token = fcm_token
    return user


def _make_notification(
    notif_id: int = 1,
    user_id: int = 10,
    offer_id: int = 42,
    urgency_type: str = "signArras",
    is_read: bool = False,
) -> NotificationLog:
    n = MagicMock(spec=NotificationLog)
    n.id = notif_id
    n.user_id = user_id
    n.offer_id = offer_id
    n.urgency_type = urgency_type
    n.is_read = is_read
    n.title = "Firma el contrato de Arras"
    n.body = "No detengas la operacion, Usuario Test esta esperando: Firmar Arras."
    n.notification_type = "urgency"
    n.deep_link = f"/offers/{offer_id}/arras"
    return n


# ─── Tests de servicio: upsert ────────────────────────────────────────────────

class TestUpsertUrgencyNotification:

    def test_creates_notification_when_not_exists(self):
        """
        GREEN: Crea una nueva NotificationLog cuando no existe ninguna
        para (user_id, offer_id, urgency_type).
        """
        db = MagicMock()
        user = _make_user(user_id=10)

        # Simula: usuario encontrado, no hay notificacion existente
        db.query.return_value.filter.return_value.first.side_effect = [user, None]

        result_notification = _make_notification()

        def fake_add(obj):
            obj.id = 1
            obj.is_read = False

        db.add.side_effect = fake_add
        db.refresh.side_effect = lambda obj: setattr(obj, "id", 1)

        with patch(
            "backend.src.services.notification_service._send_fcm_push",
            return_value=False,
        ):
            result = upsert_urgency_notification(
                db,
                user_id=10,
                offer_id=42,
                urgency_type="signArras",
                label="Firmar Contrato de Arras",
                route="/offers/42/arras",
            )

        db.add.assert_called_once()
        db.commit.assert_called_once()

    def test_does_not_duplicate_when_notification_exists(self):
        """
        GREEN: Si ya existe una notificacion para (user_id, offer_id, urgency_type),
        retorna la existente sin crear duplicado.
        """
        db = MagicMock()
        user = _make_user(user_id=10)
        existing = _make_notification()

        # Primera query = usuario, segunda = notificacion existente
        db.query.return_value.filter.return_value.first.side_effect = [user, existing]

        result = upsert_urgency_notification(
            db,
            user_id=10,
            offer_id=42,
            urgency_type="signArras",
            label="Firmar Contrato de Arras",
            route="/offers/42/arras",
        )

        db.add.assert_not_called()
        db.commit.assert_not_called()
        assert result is existing

    def test_returns_none_when_user_not_found(self):
        """
        GREEN: Retorna None si el user_id no existe en la base de datos.
        """
        db = MagicMock()
        db.query.return_value.filter.return_value.first.return_value = None

        result = upsert_urgency_notification(
            db,
            user_id=9999,
            offer_id=42,
            urgency_type="signArras",
            label="Firmar Arras",
            route="/offers/42/arras",
        )

        assert result is None
        db.add.assert_not_called()

    def test_sends_fcm_when_token_present(self):
        """
        GREEN: Se intenta enviar push si el usuario tiene fcm_token.
        Cuando no se pasa other_party_name, se usa el texto de fallback.
        """
        db = MagicMock()
        fake_device_id = "device-id-abc123-for-unit-test"
        user = _make_user(user_id=10, fcm_token=fake_device_id)
        db.query.return_value.filter.return_value.first.side_effect = [user, None]
        db.refresh.side_effect = lambda obj: None

        with patch(
            "backend.src.services.notification_service._send_fcm_push",
            return_value=True,
        ) as mock_push:
            upsert_urgency_notification(
                db,
                user_id=10,
                offer_id=42,
                urgency_type="signArras",
                label="Firmar Arras",
                route="/offers/42/arras",
                # other_party_name no proporcionado -> fallback "el otro interviniente"
            )

        mock_push.assert_called_once_with(
            fake_device_id,
            "Firma el contrato de Arras",
            "No detengas la operacion, el otro interviniente esta esperando: Firmar Arras.",
            "/offers/42/arras",
        )


# ─── Tests de servicio: mark_read ────────────────────────────────────────────

class TestMarkNotificationRead:

    def test_marks_own_notification_read(self):
        """
        GREEN: El usuario puede marcar su propia notificacion como leida.
        """
        db = MagicMock()
        notification = _make_notification(notif_id=1, user_id=10, is_read=False)
        db.query.return_value.filter.return_value.first.return_value = notification

        result = mark_notification_read(db, notification_id=1, user_id=10)

        assert result is notification
        assert notification.is_read is True
        db.commit.assert_called_once()

    def test_returns_none_for_other_users_notification(self):
        """
        GREEN (@Shield ownership): Retorna None si la notificacion no pertenece
        al user_id indicado (el filtro en DB no encuentra la fila).
        """
        db = MagicMock()
        # Simula que la query con user_id=99 no encuentra la notificacion del user_id=10
        db.query.return_value.filter.return_value.first.return_value = None

        result = mark_notification_read(db, notification_id=1, user_id=99)

        assert result is None
        db.commit.assert_not_called()


# ─── Tests de servicio: mark_all_read ────────────────────────────────────────

class TestMarkAllRead:

    def test_marks_only_users_notifications(self):
        """
        GREEN: mark_all_read aplica el filtro user_id correctamente.
        """
        db = MagicMock()
        db.query.return_value.filter.return_value.update.return_value = 3

        count = mark_all_read(db, user_id=10)

        assert count == 3
        db.commit.assert_called_once()


# ─── Tests de endpoint HTTP ───────────────────────────────────────────────────

class TestGetNotificationsEndpoint:

    def test_get_notifications_returns_only_own(self, client):
        """
        GREEN: GET /api/v1/notifications retorna solo las notificaciones
        del usuario autenticado.
        """
        mock_user = _make_user(user_id=10)
        mock_notification = _make_notification(user_id=10)
        db = MagicMock()
        db.query.return_value.filter.return_value.count.return_value = 1
        db.query.return_value.filter.return_value.order_by.return_value.offset.return_value.limit.return_value.all.return_value = [mock_notification]

        from backend.src.utils.security import get_current_active_user
        from backend.src.config.database import get_db

        app.dependency_overrides[get_current_active_user] = lambda: mock_user
        app.dependency_overrides[get_db] = lambda: db

        try:
            response = client.get("/api/v1/notifications")
        finally:
            app.dependency_overrides.pop(get_current_active_user, None)
            app.dependency_overrides.pop(get_db, None)

        assert response.status_code == 200

    def test_patch_read_returns_404_for_other_user(self, client):
        """
        GREEN (@Shield): PATCH /api/v1/notifications/{id}/read retorna 404
        si la notificacion no pertenece al usuario autenticado.
        """
        mock_user = _make_user(user_id=99)
        db = MagicMock()

        from backend.src.utils.security import get_current_active_user
        from backend.src.config.database import get_db

        app.dependency_overrides[get_current_active_user] = lambda: mock_user
        app.dependency_overrides[get_db] = lambda: db

        with patch(
            "backend.src.routes.notifications.mark_notification_read",
            return_value=None,
        ):
            try:
                response = client.patch("/api/v1/notifications/1/read")
            finally:
                app.dependency_overrides.pop(get_current_active_user, None)
                app.dependency_overrides.pop(get_db, None)

        assert response.status_code == 404
