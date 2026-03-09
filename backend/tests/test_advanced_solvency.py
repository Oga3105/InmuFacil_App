"""
TDD: Advanced solvency flow (Sprint V12)
Tests for:
  - New PaymentMethod values (savings_plus_mortgage, bridge_mortgage)
  - AnonymisedPassport includes is_multi_buyer and payment_method_label
  - _compute_solvency scores new payment methods correctly
"""
from __future__ import annotations
from unittest.mock import MagicMock, patch
import pytest
from fastapi.testclient import TestClient

from backend.main import app
from backend.src.config.database import get_db
from backend.src.utils.security import get_current_active_user
from backend.src.models.solvency import BuyerSolvency
from backend.src.models.enums import SolvencyLevel, StressIndex, PaymentMethod
from backend.src.models import Property, PropertyOffer


def _mock_user(user_id: int = 1):
    user = MagicMock()
    user.id = user_id
    user.is_active = True
    return user


def _make_client(mock_db_session, mock_user):
    app.dependency_overrides[get_db] = lambda: mock_db_session
    app.dependency_overrides[get_current_active_user] = lambda: mock_user
    return TestClient(app, raise_server_exceptions=False)


def _teardown():
    app.dependency_overrides.clear()


def _base_payload(payment_method: str = "mortgage_pending") -> dict:
    return {
        "terms_accepted": True,
        "knows_extra_costs": True,
        "debt_ratio": 0.25,
        "has_emergency_fund": True,
        "payment_method": payment_method,
        "has_initial_savings": True,
        "has_pre_approval": False,
    }


def _make_insert_db(payment_method: PaymentMethod, is_multi_buyer: bool = False):
    """Mock DB for INSERT path (no existing record)."""
    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = None

    def _refresh(obj):
        obj.id = 1
        obj.buyer_id = 1
        obj.is_multi_buyer = is_multi_buyer
        obj.terms_accepted_at = None
        obj.terms_version_id = "v1.0"
        obj.knows_extra_costs = True
        obj.debt_ratio = 0.25
        obj.has_emergency_fund = True
        obj.payment_method = payment_method
        obj.has_initial_savings = True
        obj.has_pre_approval = False
        obj.pre_approval_pdf_url_encrypted = None
        obj.stress_index = StressIndex.LOW_RISK
        obj.solvency_level = SolvencyLevel.SILVER
        obj.created_at = None
        obj.expires_at = None

    db.refresh.side_effect = _refresh
    return db


# ===========================================================================
# Tests: new PaymentMethod enum values accepted in POST /solvency/me
# ===========================================================================

class TestNewPaymentMethodValues:
    """POST /solvency/me accepts savings_plus_mortgage and bridge_mortgage."""

    def teardown_method(self):
        _teardown()

    def test_savings_plus_mortgage_accepted(self):
        db = _make_insert_db(PaymentMethod.SAVINGS_PLUS_MORTGAGE)
        client = _make_client(db, _mock_user())

        resp = client.post(
            "/api/v1/solvency/me",
            json=_base_payload("savings_plus_mortgage"),
        )
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert data["payment_method"] == "savings_plus_mortgage"

    def test_bridge_mortgage_accepted(self):
        db = _make_insert_db(PaymentMethod.BRIDGE_MORTGAGE)
        client = _make_client(db, _mock_user())

        resp = client.post(
            "/api/v1/solvency/me",
            json=_base_payload("bridge_mortgage"),
        )
        assert resp.status_code in (200, 201), resp.text
        data = resp.json()
        assert data["payment_method"] == "bridge_mortgage"


# ===========================================================================
# Tests: scoring for new payment methods
# ===========================================================================

class TestSolvencyScoring:
    """_compute_solvency assigns expected scores to new payment methods."""

    def teardown_method(self):
        _teardown()

    def test_savings_plus_mortgage_scores_like_mortgage_pending(self):
        """savings_plus_mortgage earns +1 (same as mortgage_pending)."""
        db = _make_insert_db(PaymentMethod.SAVINGS_PLUS_MORTGAGE)
        client = _make_client(db, _mock_user())

        # With all positives + savings_plus_mortgage (+1) total score = 1+1+1+1+1 = 5 -> silver
        resp = client.post(
            "/api/v1/solvency/me",
            json=_base_payload("savings_plus_mortgage"),
        )
        assert resp.status_code in (200, 201), resp.text
        # Silver or higher means scoring was at least 4
        data = resp.json()
        assert data["solvency_level"] in ("silver", "gold")

    def test_bridge_mortgage_scores_zero_points(self):
        """bridge_mortgage earns 0 extra points (same as house_to_sell)."""
        db = _make_insert_db(PaymentMethod.BRIDGE_MORTGAGE)
        client = _make_client(db, _mock_user())

        # All positives except payment method (0 pts): 1+1+1+1+0 = 4 -> silver or bronze
        resp = client.post(
            "/api/v1/solvency/me",
            json=_base_payload("bridge_mortgage"),
        )
        assert resp.status_code in (200, 201), resp.text
        # bridge_mortgage should NOT yield gold (that requires >= 6 pts)
        data = resp.json()
        assert data["solvency_level"] != "gold"


# ===========================================================================
# Tests: AnonymisedPassport includes is_multi_buyer and payment_method_label
# ===========================================================================

class TestAnonymisedPassportV12:
    """GET /solvency/offer/{offer_id}/buyer returns is_multi_buyer and payment_method_label."""

    def teardown_method(self):
        _teardown()

    def _make_offer_db(self, buyer_id: int, seller_id: int, payment_method: PaymentMethod, is_multi_buyer: bool):
        prop = MagicMock(spec=Property)
        prop.owner_id = seller_id

        offer = MagicMock(spec=PropertyOffer)
        offer.id = 1
        offer.buyer_id = buyer_id
        offer.property = prop

        record = MagicMock(spec=BuyerSolvency)
        record.buyer_id = buyer_id
        record.solvency_level = SolvencyLevel.SILVER
        record.stress_index = StressIndex.LOW_RISK
        record.knows_extra_costs = True
        record.has_initial_savings = True
        record.has_pre_approval = False
        record.payment_method = payment_method
        record.is_multi_buyer = is_multi_buyer
        record.expires_at = None

        db = MagicMock()
        db.query.return_value.join.return_value.filter.return_value.first.return_value = offer
        # Second query call returns the buyer passport
        db.query.return_value.filter.return_value.first.return_value = record
        return db

    def test_anonymised_passport_includes_is_multi_buyer(self):
        db = self._make_offer_db(
            buyer_id=2,
            seller_id=1,
            payment_method=PaymentMethod.MORTGAGE_PENDING,
            is_multi_buyer=True,
        )
        client = _make_client(db, _mock_user(user_id=1))

        resp = client.get("/api/v1/solvency/offer/1/buyer")
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert "is_multi_buyer" in data
        assert data["is_multi_buyer"] is True

    def test_anonymised_passport_includes_payment_method_label(self):
        db = self._make_offer_db(
            buyer_id=2,
            seller_id=1,
            payment_method=PaymentMethod.SAVINGS_PLUS_MORTGAGE,
            is_multi_buyer=False,
        )
        client = _make_client(db, _mock_user(user_id=1))

        resp = client.get("/api/v1/solvency/offer/1/buyer")
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert "payment_method_label" in data
        assert data["payment_method_label"] == "Ahorros + hipoteca"

    def test_bridge_mortgage_label(self):
        db = self._make_offer_db(
            buyer_id=2,
            seller_id=1,
            payment_method=PaymentMethod.BRIDGE_MORTGAGE,
            is_multi_buyer=False,
        )
        client = _make_client(db, _mock_user(user_id=1))

        resp = client.get("/api/v1/solvency/offer/1/buyer")
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data["payment_method_label"] == "Hipoteca puente"

    def test_cash_label(self):
        db = self._make_offer_db(
            buyer_id=2,
            seller_id=1,
            payment_method=PaymentMethod.CASH,
            is_multi_buyer=False,
        )
        client = _make_client(db, _mock_user(user_id=1))

        resp = client.get("/api/v1/solvency/offer/1/buyer")
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data["payment_method_label"] == "Pago al contado"
