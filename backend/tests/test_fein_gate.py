"""
@Jules — TDD Red Phase: FEIN Access Gate

Tests that the FEIN (Ficha Europea de Informacion Normalizada) confirmation
endpoint is only accessible when the TASACION_APPOINTMENT timeline step
is COMPLETED for the offer.

Run: pytest backend/tests/test_fein_gate.py -v
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from backend.main import app
from backend.src.models.timeline import StepStatus


@pytest.fixture
def client():
    return TestClient(app)


class TestFeinAccessGate:
    """
    Gate rule: POST /api/v1/fein/{offer_id}/confirm returns 403
    when the TASACION_APPOINTMENT timeline step is not COMPLETED.
    Returns 200 when it IS completed.
    """

    def test_fein_confirm_forbidden_when_tasacion_pending(self, client):
        """
        RED: Buyer cannot confirm FEIN if TASACION_APPOINTMENT step is PENDING.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.fein.get_current_active_user") as mock_user,
            patch("backend.src.routes.fein.get_db") as mock_db,
            patch("backend.src.routes.fein._get_tasacion_step_status") as mock_step,
        ):
            mock_user.return_value = MagicMock(id=2, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.PENDING

            response = client.post(
                f"/api/v1/fein/{offer_id}/confirm",
                headers={"Authorization": "Bearer test-token-2"},
                json={"role": "BUYER", "notes": "Banco ha enviado la FEIN"},
            )

        assert response.status_code == 403
        detail = response.json().get("detail", "").lower()
        assert any(
            word in detail for word in ["tasacion", "appraisal", "previa", "tasac"]
        )

    def test_fein_confirm_forbidden_when_tasacion_partial(self, client):
        """
        RED: FEIN is blocked if only one party confirmed the tasacion appointment.
        PARTIALLY_COMPLETED is not enough — both must have confirmed.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.fein.get_current_active_user") as mock_user,
            patch("backend.src.routes.fein.get_db") as mock_db,
            patch("backend.src.routes.fein._get_tasacion_step_status") as mock_step,
        ):
            mock_user.return_value = MagicMock(id=2, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.PARTIALLY_COMPLETED

            response = client.post(
                f"/api/v1/fein/{offer_id}/confirm",
                headers={"Authorization": "Bearer test-token-2"},
                json={"role": "BUYER"},
            )

        assert response.status_code == 403

    def test_fein_confirm_allowed_when_tasacion_completed(self, client):
        """
        RED: Buyer CAN confirm FEIN when TASACION_APPOINTMENT step is COMPLETED.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.fein.get_current_active_user") as mock_user,
            patch("backend.src.routes.fein.get_db") as mock_db,
            patch("backend.src.routes.fein._get_tasacion_step_status") as mock_step,
            patch("backend.src.routes.fein._confirm_fein_step") as mock_confirm,
        ):
            mock_user.return_value = MagicMock(id=2, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.COMPLETED
            mock_confirm.return_value = {"offer_id": offer_id, "fein_status": "confirmed"}

            response = client.post(
                f"/api/v1/fein/{offer_id}/confirm",
                headers={"Authorization": "Bearer test-token-2"},
                json={"role": "BUYER", "notes": "FEIN recibida"},
            )

        assert response.status_code == 200

    def test_fein_status_returns_403_when_tasacion_not_done(self, client):
        """
        RED: GET /fein/{offer_id}/status also gates on tasacion completion.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.fein.get_current_active_user") as mock_user,
            patch("backend.src.routes.fein.get_db") as mock_db,
            patch("backend.src.routes.fein._get_tasacion_step_status") as mock_step,
        ):
            mock_user.return_value = MagicMock(id=1, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.PENDING

            response = client.get(
                f"/api/v1/fein/{offer_id}/status",
                headers={"Authorization": "Bearer test-token-1"},
            )

        assert response.status_code == 403


class TestFeinAutoMessage:
    """
    Tests that confirming FEIN as BUYER triggers an automatic chat message,
    and confirming as SELLER does not.
    """

    def test_confirm_fein_step_buyer_calls_auto_message(self):
        """
        GREEN: _confirm_fein_step with role=BUYER calls _send_fein_auto_message.
        """
        from backend.src.routes.fein import _confirm_fein_step

        mock_db = MagicMock()
        mock_step = MagicMock()
        mock_step.status = StepStatus.PARTIALLY_COMPLETED
        mock_step.buyer_confirmed_at = None
        mock_step.seller_confirmed_at = None
        mock_step.metadata_json = {}
        mock_db.query.return_value.filter.return_value.first.return_value = mock_step

        with patch("backend.src.routes.fein._send_fein_auto_message") as mock_auto_msg:
            _confirm_fein_step(
                offer_id=42, user_id=10, role="BUYER", notes="", db=mock_db
            )

        mock_auto_msg.assert_called_once_with(offer_id=42, buyer_id=10, db=mock_db)

    def test_confirm_fein_step_seller_does_not_call_auto_message(self):
        """
        GREEN: _confirm_fein_step with role=SELLER does NOT call _send_fein_auto_message.
        The auto-message is buyer-only — it notifies the seller of bank approval.
        """
        from backend.src.routes.fein import _confirm_fein_step

        mock_db = MagicMock()
        mock_step = MagicMock()
        mock_step.status = StepStatus.PARTIALLY_COMPLETED
        mock_step.buyer_confirmed_at = MagicMock()  # buyer already confirmed
        mock_step.seller_confirmed_at = None
        mock_step.metadata_json = {}
        mock_db.query.return_value.filter.return_value.first.return_value = mock_step

        with patch("backend.src.routes.fein._send_fein_auto_message") as mock_auto_msg:
            _confirm_fein_step(
                offer_id=42, user_id=99, role="SELLER", notes="", db=mock_db
            )

        mock_auto_msg.assert_not_called()

    def test_send_fein_auto_message_content(self):
        """
        Unit test: _send_fein_auto_message inserts an OfferMessage with the
        correct action_type and display_text.
        Patches source modules since imports inside _send_fein_auto_message are local.
        """
        from backend.src.routes.fein import _send_fein_auto_message, _FEIN_AUTO_MESSAGE

        mock_db = MagicMock()
        msg_instance = MagicMock()
        msg_instance.timestamp = None

        with (
            patch("backend.src.models.offers.OfferMessage", return_value=msg_instance) as mock_msg_cls,
            patch("backend.src.utils.crypto.encrypt_data", return_value="encrypted"),
            patch("backend.src.services.chat_service.CensorshipFilter") as mock_censor,
            patch("backend.src.services.chat_service.manager"),
        ):
            mock_censor.sanitize.return_value = _FEIN_AUTO_MESSAGE

            _send_fein_auto_message(offer_id=42, buyer_id=10, db=mock_db)

        mock_msg_cls.assert_called_once()
        call_kwargs = mock_msg_cls.call_args.kwargs
        assert call_kwargs["message_type"] == "action"
        assert call_kwargs["action_data"]["action_type"] == "fein_bank_approved"
        assert "aprobacion bancaria final" in call_kwargs["action_data"]["display_text"]
        mock_db.add.assert_called_once_with(msg_instance)
