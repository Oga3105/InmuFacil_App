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
