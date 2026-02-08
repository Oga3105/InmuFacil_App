"""
@Shield - Security Utilities (OWASP Compliance)

Password hashing and verification using Bcrypt.
Implements OWASP best practices for password security.

Token Consumption Tracking: ~500 tokens for security implementation
"""

from passlib.context import CryptContext

# Bcrypt password hashing context
# Bcrypt is recommended by OWASP for password hashing
# Automatically handles salting and multiple rounds
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """
    Hash a plain text password using Bcrypt.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Hashed password string
        
    Security Notes:
    - Uses Bcrypt algorithm (OWASP recommended)
    - Automatically generates unique salt per password
    - Computationally expensive to prevent brute force attacks
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain text password against a hashed password.
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Hashed password to compare against
        
    Returns:
        True if password matches, False otherwise
        
    Security Notes:
    - Constant-time comparison to prevent timing attacks
    - Never logs or stores the plain password
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """
    Alias for hash_password for backwards compatibility.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Hashed password string
    """
    return hash_password(password)
