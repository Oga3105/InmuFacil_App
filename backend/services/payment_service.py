"""
@Shield - Payment Gateway Abstraction (Mock)

Simulates a PCI-Compliant Payment Provider (like Stripe).
For Hito 8, this allows us to test the Reservation flow without real money.
"""

import uuid
from typing import Tuple, Optional

class PaymentError(Exception):
    pass

class MockPaymentProvider:
    """
    Simulates external payment processing.
    """
    
    @staticmethod
    def process_payment(amount: float, token: str, idempotency_key: str) -> Tuple[bool, str, Optional[str]]:
        """
        Process a charge.
        
        Args:
            amount: Amount to charge
            token: Card token (e.g. "tok_visa")
            idempotency_key: Unique request ID
            
        Returns:
            (success, transaction_id, error_message)
        """
        # Simulate Network Latency? No need for TDD.
        
        # Test Cards
        if token == "tok_fail":
            return False, None, "Card declined: Insufficient funds"
            
        if token == "tok_network_error":
            raise PaymentError("Connection to payment gateway timed out")
            
        # Success Case
        # Generate a fake transaction ID
        tx_id = f"ch_{uuid.uuid4().hex[:16]}"
        return True, tx_id, None

def get_payment_provider():
    return MockPaymentProvider()
