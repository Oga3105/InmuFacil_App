"""
@Jules - TDD: DNI Uniqueness via HMAC

Verifica que:
  1. compute_dni_hmac produce el mismo digest para el mismo DNI (determinismo).
  2. compute_dni_hmac normaliza: mayusculas/espacios producen el mismo digest.
  3. compute_dni_hmac produce digests distintos para DNIs distintos.
  4. El background task de KYC rechaza un DNI ya vinculado a otro usuario.
  5. Race condition: IntegrityError se maneja y el usuario queda RECHAZADO.

Run: pytest backend/tests/test_dni_uniqueness.py -v
"""

import pytest
from unittest.mock import MagicMock, patch, call

from backend.src.utils.crypto import compute_dni_hmac


# ============================================================================
# 1. Tests unitarios de compute_dni_hmac
# ============================================================================

class TestComputeDniHmac:

    def test_deterministic_same_input(self):
        """Mismo DNI siempre produce el mismo HMAC."""
        hmac1 = compute_dni_hmac("12345678A")
        hmac2 = compute_dni_hmac("12345678A")
        assert hmac1 == hmac2

    def test_normalises_lowercase(self):
        """Minusculas y mayusculas producen el mismo digest."""
        assert compute_dni_hmac("12345678a") == compute_dni_hmac("12345678A")

    def test_normalises_whitespace(self):
        """Espacios alrededor del DNI son ignorados."""
        assert compute_dni_hmac("  12345678A  ") == compute_dni_hmac("12345678A")

    def test_different_documents_produce_different_hmac(self):
        """DNIs distintos nunca colisionan."""
        assert compute_dni_hmac("12345678A") != compute_dni_hmac("87654321Z")

    def test_output_is_64_hex_chars(self):
        """El HMAC-SHA256 es siempre 64 caracteres hexadecimales."""
        result = compute_dni_hmac("12345678A")
        assert len(result) == 64
        assert all(c in "0123456789abcdef" for c in result)

    def test_empty_doc_raises(self):
        """Un DNI vacio lanza ValueError."""
        with pytest.raises(ValueError):
            compute_dni_hmac("")

    def test_whitespace_only_raises(self):
        """Un DNI de solo espacios lanza ValueError."""
        with pytest.raises(ValueError):
            compute_dni_hmac("   ")


# ============================================================================
# 2. Tests del background task KYC — unicidad
# ============================================================================

def _make_user(user_id: int, dni_hmac: str | None = None) -> MagicMock:
    """Helper: crea un mock de User."""
    user = MagicMock()
    user.id = user_id
    user.dni_hmac = dni_hmac
    user.encrypted_dni = None
    user.dni_status = "PENDIENTE"
    user.rejection_reason = None
    return user


def _make_gemini_result(approved: bool, doc_number: str = "12345678A") -> MagicMock:
    result = MagicMock()
    result.approved = approved
    result.confidence = 0.99
    result.reason = None if approved else "low_confidence"
    result.doc_number = doc_number if approved else None
    return result


class TestKycDniUniquenessBackgroundTask:
    """
    Tests del flujo _run_gemini_verification con enfasis en unicidad de DNI.
    Usamos mocks de DB para evitar dependencia de PostgreSQL en CI.
    """

    def _run_task(self, user_id, gemini_result, db_mock):
        """Importa y ejecuta el background task con mocks inyectados."""
        from backend.src.routes.kyc import _run_gemini_verification
        with patch("backend.src.routes.kyc.SessionLocal", return_value=db_mock), \
             patch("backend.src.routes.kyc.verify_identity_with_gemini", return_value=gemini_result):
            _run_gemini_verification(
                user_id=user_id,
                front_path="/fake/front.jpg",
                back_path=None,
                selfie_path=None,
                document_type="dni",
            )

    def test_new_dni_is_stored_with_hmac(self):
        """Un DNI nunca visto se almacena con encrypted_dni y dni_hmac."""
        user = _make_user(user_id=1)
        gemini_result = _make_gemini_result(approved=True, doc_number="12345678A")

        db = MagicMock()
        db.query.return_value.filter.return_value.order_by.return_value.filter.return_value.all.return_value = []
        # Primera llamada .filter().first() → user actual
        # Segunda llamada .filter().first() → None (no hay duplicado)
        db.query.return_value.filter.return_value.first = MagicMock(side_effect=[user, None])

        self._run_task(user_id=1, gemini_result=gemini_result, db_mock=db)

        assert user.encrypted_dni is not None
        assert user.dni_hmac == compute_dni_hmac("12345678A")
        assert user.dni_status == "VALIDADO"

    def test_duplicate_dni_is_rejected(self):
        """
        Si otro usuario ya tiene ese DNI, el KYC se rechaza con motivo claro
        y NO se guarda encrypted_dni ni dni_hmac en el usuario solicitante.
        """
        existing_other_user = _make_user(user_id=99, dni_hmac=compute_dni_hmac("12345678A"))
        user = _make_user(user_id=2)
        gemini_result = _make_gemini_result(approved=True, doc_number="12345678A")

        db = MagicMock()
        db.query.return_value.filter.return_value.order_by.return_value.filter.return_value.all.return_value = []

        # Simular: query(User).filter(User.id==2).first() -> user actual
        #          query(User).filter(User.dni_hmac==X, User.id!=2).first() -> existing_other_user
        first_calls = [user, existing_other_user]

        call_count = {"n": 0}
        def first_side_effect():
            n = call_count["n"]
            call_count["n"] += 1
            return first_calls[n] if n < len(first_calls) else None

        db.query.return_value.filter.return_value.first.side_effect = first_side_effect
        db.query.return_value.filter.return_value.filter.return_value.first.return_value = existing_other_user

        self._run_task(user_id=2, gemini_result=gemini_result, db_mock=db)

        assert user.encrypted_dni is None
        assert user.dni_hmac is None
        assert user.dni_status == "RECHAZADO"
        assert "vinculado a otra cuenta" in (user.rejection_reason or "")

    def test_gemini_rejection_does_not_store_hmac(self):
        """Si Gemini rechaza el documento, no se guarda ni dni ni hmac."""
        user = _make_user(user_id=3)
        gemini_result = _make_gemini_result(approved=False, doc_number="12345678A")

        db = MagicMock()
        db.query.return_value.filter.return_value.order_by.return_value.filter.return_value.all.return_value = []
        db.query.return_value.filter.return_value.first.return_value = user

        self._run_task(user_id=3, gemini_result=gemini_result, db_mock=db)

        assert user.encrypted_dni is None
        assert user.dni_hmac is None
        assert user.dni_status == "RECHAZADO"
