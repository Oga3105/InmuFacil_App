"""
@Shield - Security Utilities (OWASP Compliance)

Password hashing and verification using Bcrypt.
Implements OWASP best practices for password security.

Token Consumption Tracking: ~500 tokens for security implementation
"""

import bcrypt as _bcrypt

_BCRYPT_ROUNDS = 12


def hash_password(password: str) -> str:
    """
    Hash a plain text password using bcrypt 5.x.

    Security Notes:
    - Uses bcrypt algorithm (OWASP recommended)
    - Automatically generates unique salt per password
    - Computationally expensive to prevent brute force attacks
    """
    return _bcrypt.hashpw(password.encode("utf-8"), _bcrypt.gensalt(_BCRYPT_ROUNDS)).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain text password against a bcrypt hash.

    Security Notes:
    - Constant-time comparison to prevent timing attacks
    - Never logs or stores the plain password
    """
    return _bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))


def get_password_hash(password: str) -> str:
    """
    Alias for hash_password for backwards compatibility.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Hashed password string
    """
    return hash_password(password)
