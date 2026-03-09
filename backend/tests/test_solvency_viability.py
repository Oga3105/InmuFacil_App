"""
TDD: Property Viability Endpoint (Sprint V9)
Tests for GET /solvency/viability/{property_id}
"""
from __future__ import annotations
from unittest.mock import MagicMock, patch
import pytest
from fastapi.testclient import TestClient

from backend.main import app
from backend.src.models.solvency import BuyerSolvency
from backend.src.models.properties import Property
from backend.src.models.enums import SolvencyLevel, StressIndex


@pytest.fixture
def client():
    return TestClient(app)


def _auth_headers():
    return {"Authorization": "Bearer test_token"}


def _mock_user(user_id: int = 1):
    user = MagicMock()
    user.id = user_id
    user.is_active = True
    return user


def _mock_property(price: float = 250_000.0):
    prop = MagicMock(spec=Property)
    prop.id = 1
    prop.price = price
    return prop


def _mock_passport(income_enc=None, savings_enc=None, debt_enc=None):
    passport = MagicMock(spec=BuyerSolvency)
    passport.buyer_id = 1
    passport.net_monthly_income_enc = income_enc
    passport.total_savings_enc = savings_enc
    passport.total_monthly_debt_enc = debt_enc
    passport.solvency_level = SolvencyLevel.SILVER
    passport.stress_index = StressIndex.LOW_RISK
    return passport


class TestViabilityNoPassport:
    """User has no solvency passport at all."""

    @patch("backend.src.routes.solvency.get_current_active_user")
    @patch("backend.src.routes.solvency.get_db")
    def test_returns_insufficient_data_when_no_passport(self, mock_db, mock_auth, client):
        mock_auth.return_value = _mock_user()
        db = MagicMock()
        db.query.return_value.filter.return_value.first.side_effect = [
            _mock_property(250_000),   # Property query
            None,                       # Passport query
        ]
        mock_db.return_value = db

        resp = client.get("/api/v1/solvency/viability/1", headers=_auth_headers())
        assert resp.status_code == 200
        data = resp.json()
        assert data["verdict"] == "insufficient_data"
        assert data["has_financial_dna"] is False


class TestViabilityNoQuantitativeData:
    """Passport exists but has no ADN Financiero (encrypted fields are None)."""

    @patch("backend.src.routes.solvency.get_current_active_user")
    @patch("backend.src.routes.solvency.get_db")
    def test_returns_insufficient_data_when_no_adn(self, mock_db, mock_auth, client):
        mock_auth.return_value = _mock_user()
        db = MagicMock()
        db.query.return_value.filter.return_value.first.side_effect = [
            _mock_property(250_000),
            _mock_passport(income_enc=None, savings_enc=None),
        ]
        mock_db.return_value = db

        resp = client.get("/api/v1/solvency/viability/1", headers=_auth_headers())
        assert resp.status_code == 200
        data = resp.json()
        assert data["verdict"] == "insufficient_data"
        assert data["has_financial_dna"] is False


class TestViabilityGreenVerdic:
    """Buyer has strong savings (>20% entry) and low DTI (<35%)."""

    @patch("backend.src.routes.solvency.decrypt_data")
    @patch("backend.src.routes.solvency.get_current_active_user")
    @patch("backend.src.routes.solvency.get_db")
    def test_green_verdict_strong_buyer(self, mock_db, mock_auth, mock_decrypt, client):
        # Property: 200k EUR → entry cost = 224k; 20% min = 44.8k
        # Income: 4000/mo; savings: 60000; debt: 0
        # Mortgage: 200k * 0.8 = 160k → ~675 EUR/mo → DTI = 675/4000 = 0.169 < 0.35
        mock_auth.return_value = _mock_user()
        db = MagicMock()
        passport = _mock_passport(income_enc="enc_i", savings_enc="enc_s", debt_enc="enc_d")
        db.query.return_value.filter.return_value.first.side_effect = [
            _mock_property(200_000),
            passport,
        ]
        mock_db.return_value = db

        mock_decrypt.side_effect = lambda enc: {
            "enc_i": "4000",
            "enc_s": "60000",
            "enc_d": "0",
        }[enc]

        resp = client.get("/api/v1/solvency/viability/1", headers=_auth_headers())
        assert resp.status_code == 200
        data = resp.json()
        assert data["verdict"] == "green"
        assert data["has_financial_dna"] is True
        assert data["dti_ratio"] < 0.35


class TestViabilityRedVerdict:
    """Buyer has insufficient savings and high DTI."""

    @patch("backend.src.routes.solvency.decrypt_data")
    @patch("backend.src.routes.solvency.get_current_active_user")
    @patch("backend.src.routes.solvency.get_db")
    def test_red_verdict_insufficient_buyer(self, mock_db, mock_auth, mock_decrypt, client):
        # Property: 500k EUR → entry cost = 560k; 15% min = 84k
        # Income: 2500/mo; savings: 20000 (<<84k); debt: 800
        mock_auth.return_value = _mock_user()
        db = MagicMock()
        passport = _mock_passport(income_enc="enc_i", savings_enc="enc_s", debt_enc="enc_d")
        db.query.return_value.filter.return_value.first.side_effect = [
            _mock_property(500_000),
            passport,
        ]
        mock_db.return_value = db

        mock_decrypt.side_effect = lambda enc: {
            "enc_i": "2500",
            "enc_s": "20000",
            "enc_d": "800",
        }[enc]

        resp = client.get("/api/v1/solvency/viability/1", headers=_auth_headers())
        assert resp.status_code == 200
        data = resp.json()
        assert data["verdict"] == "red"
        assert data["has_financial_dna"] is True


class TestViabilityPropertyNotFound:
    """Property does not exist."""

    @patch("backend.src.routes.solvency.get_current_active_user")
    @patch("backend.src.routes.solvency.get_db")
    def test_404_when_property_not_found(self, mock_db, mock_auth, client):
        mock_auth.return_value = _mock_user()
        db = MagicMock()
        db.query.return_value.filter.return_value.first.return_value = None
        mock_db.return_value = db

        resp = client.get("/api/v1/solvency/viability/9999", headers=_auth_headers())
        assert resp.status_code == 404
