"""
@Jules — TDD Red Phase: Post-Sale Document Access Gate

Tests that post-sale documents are only accessible when the notary
signing step (DEED_SIGNATURE) is COMPLETED for the offer.

Run: pytest backend/tests/test_post_sale_gate.py -v
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from backend.main import app
from backend.src.models.timeline import StepStatus


# ─── Fixtures ─────────────────────────────────────────────────────────────────

@pytest.fixture
def client():
    return TestClient(app)


def _make_auth_headers(user_id: int = 1, user_type: str = "PARTICULAR"):
    """Helper to produce a mock auth token header."""
    # In real tests this would generate a valid JWT. For unit tests we mock auth.
    return {"Authorization": f"Bearer test-token-{user_id}"}


# ─── Gate tests ───────────────────────────────────────────────────────────────

class TestPostSaleAccessGate:
    """
    Gate rule: POST /api/v1/post-sale/{offer_id}/documents returns 403
    when the DEED_SIGNATURE timeline step is not COMPLETED.
    Returns 200 when it IS completed.
    """

    def test_upload_forbidden_when_deed_not_signed(self, client):
        """
        RED: A seller cannot upload post-sale documents if DEED_SIGNATURE
        step is still PENDING or PARTIALLY_COMPLETED.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.post_sale.get_current_active_user") as mock_user,
            patch("backend.src.routes.post_sale.get_db") as mock_db,
            patch("backend.src.routes.post_sale._get_deed_step_status") as mock_step,
        ):
            mock_user.return_value = MagicMock(id=1, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.PENDING  # Not completed

            response = client.post(
                f"/api/v1/post-sale/{offer_id}/documents",
                headers=_make_auth_headers(1),
                data={"doc_type": "electricity"},
                files={"file": ("factura.pdf", b"PDF content", "application/pdf")},
            )

        assert response.status_code == 403
        assert "notaria" in response.json()["detail"].lower() or \
               "deed" in response.json()["detail"].lower() or \
               "firma" in response.json()["detail"].lower()

    def test_upload_allowed_when_deed_signed(self, client):
        """
        RED: A seller CAN upload post-sale documents when DEED_SIGNATURE
        step is COMPLETED.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.post_sale.get_current_active_user") as mock_user,
            patch("backend.src.routes.post_sale.get_db") as mock_db,
            patch("backend.src.routes.post_sale._get_deed_step_status") as mock_step,
            patch("backend.src.routes.post_sale._save_post_sale_document") as mock_save,
        ):
            mock_user.return_value = MagicMock(id=1, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.COMPLETED
            mock_save.return_value = {"id": 1, "doc_type": "electricity", "filename": "factura.pdf"}

            response = client.post(
                f"/api/v1/post-sale/{offer_id}/documents",
                headers=_make_auth_headers(1),
                data={"doc_type": "electricity"},
                files={"file": ("factura.pdf", b"PDF content", "application/pdf")},
            )

        assert response.status_code == 200

    def test_download_forbidden_when_deed_not_signed(self, client):
        """
        RED: A buyer cannot download post-sale documents if DEED_SIGNATURE
        step is not COMPLETED.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.post_sale.get_current_active_user") as mock_user,
            patch("backend.src.routes.post_sale.get_db") as mock_db,
            patch("backend.src.routes.post_sale._get_deed_step_status") as mock_step,
        ):
            mock_user.return_value = MagicMock(id=2, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.PARTIALLY_COMPLETED

            response = client.get(
                f"/api/v1/post-sale/{offer_id}/documents",
                headers=_make_auth_headers(2),
            )

        assert response.status_code == 403

    def test_download_allowed_when_deed_signed(self, client):
        """
        RED: A buyer CAN list post-sale documents when DEED_SIGNATURE is COMPLETED.
        """
        offer_id = 999
        with (
            patch("backend.src.routes.post_sale.get_current_active_user") as mock_user,
            patch("backend.src.routes.post_sale.get_db") as mock_db,
            patch("backend.src.routes.post_sale._get_deed_step_status") as mock_step,
            patch("backend.src.routes.post_sale._list_post_sale_documents") as mock_list,
        ):
            mock_user.return_value = MagicMock(id=2, user_type="PARTICULAR")
            mock_db.return_value = MagicMock()
            mock_step.return_value = StepStatus.COMPLETED
            mock_list.return_value = []

            response = client.get(
                f"/api/v1/post-sale/{offer_id}/documents",
                headers=_make_auth_headers(2),
            )

        assert response.status_code == 200
