import abc
import secrets
import logging
from datetime import datetime, timedelta
from typing import Optional

logger = logging.getLogger(__name__)

class SignatureProvider(abc.ABC):
    """
    Abstract Interface for Digital Signature Providers (Hexagonal Port).
    """
    
    @abc.abstractmethod
    async def request_signature(self, offer_id: int, signer_email: str, signer_name: str, document_url: str) -> str:
        """
        Initiates the signature process.
        Returns a unique signature_token or request_id.
        """
        pass

    @abc.abstractmethod
    async def verify_signature(self, token: str) -> bool:
        """
        Verifies if a token corresponds to a successful signature event.
        Returns True if signed.
        """
        pass

class MockSignatureProvider(SignatureProvider):
    """
    Simulates a signature provider (like Signaturit) for Development.
    Uses generic logging to simulate email delivery.
    """
    
    def __init__(self):
        self._tokens = {} # In-memory storage for dev (In Prod, this state is in the Provider)

    async def request_signature(self, offer_id: int, signer_email: str, signer_name: str, document_url: str) -> str:
        # 1. Generate a secure random token
        token = secrets.token_urlsafe(32)
        
        # 2. Log the "Email" (Simulation)
        logger.info(f"--- [MOCK EMAIL] SIGNATURE REQUEST ---")
        logger.info(f"To: {signer_name} <{signer_email}>")
        logger.info(f"Subject: Please sign the Arras Contract for Offer #{offer_id}")
        logger.info(f"Link: http://localhost:8000/api/v1/contracts/sign/simulate/{token}")
        logger.info(f"--------------------------------------")
        
        # 3. Store mock state (In a real provider, we wouldn't store this, the provider handles it)
        # But for the Mock implementation to work with verify(), we need to track valid tokens.
        # Actually, in the real flow, 'verify' is usually a webhook callback or a polling endpoint.
        # Here we simulate that the token is valid.
        
        return token

    async def verify_signature(self, token: str) -> bool:
        # Logic: If token has consistent format, return True.
        # In a real scenario, we'd check against the Provider API.
        # Here, we assume if the token exists in our DB (checked by service), it's valid for the simulation.
        return True

class SignatureService:
    """
    Application Service for managing signatures.
    """
    def __init__(self, provider: SignatureProvider):
        self.provider = provider
        
    async def initiate_process(self, offer_id: int, email: str, name: str, document_path: str) -> str:
        """
        Orchestrates the signature request.
        """
        return await self.provider.request_signature(offer_id, email, name, document_path)

# Singleton / Factory for Dependency Injection
def get_signature_service():
    # In Prod, we could switch this based on env vars
    return SignatureService(MockSignatureProvider())
