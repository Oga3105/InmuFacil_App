"""
@Shield - Core Security Module (Secret Management)

Centralized cryptography and secret management for InmuFácil.
Implements AES-256-GCM encryption with fail-safe key validation.

Security Features:
- AES-256-GCM authenticated encryption
- Environment-based key management
- Fail-safe startup validation
- Key length verification

Token Consumption Tracking: ~600 tokens for security module
"""

import os
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2
from typing import Optional
import logging

logger = logging.getLogger("inmufacil.core.security")


# ============================================================================
# @Shield - Master Key Management
# ============================================================================

def get_master_key() -> bytes:
    """
    Retrieve and validate the master encryption key from environment.
    
    Returns:
        32-byte master key for AES-256-GCM
        
    Raises:
        RuntimeError: If INMUFACIL_MASTER_KEY is not set or invalid
        
    Security Notes:
    - Key MUST be 32 bytes (256 bits) when base64 decoded
    - Key is loaded from INMUFACIL_MASTER_KEY environment variable
    - Application will fail to start if key is missing (fail-safe)
    
    @Watcher: This function is called at startup for validation
    """
    master_key_b64 = os.getenv("INMUFACIL_MASTER_KEY")
    
    if not master_key_b64:
        error_msg = (
            "CRITICAL SECURITY ERROR: INMUFACIL_MASTER_KEY environment variable not set. "
            "Application cannot start without encryption key. "
            "Please set INMUFACIL_MASTER_KEY in your .env file."
        )
        logger.critical(error_msg)
        raise RuntimeError(error_msg)
    
    try:
        # Decode from base64
        master_key = base64.b64decode(master_key_b64)
        
        # Validate key length (must be exactly 32 bytes for AES-256)
        if len(master_key) != 32:
            error_msg = (
                f"CRITICAL SECURITY ERROR: INMUFACIL_MASTER_KEY has invalid length. "
                f"Expected 32 bytes, got {len(master_key)} bytes. "
                f"Please generate a new key using: python -c \"import os, base64; print(base64.b64encode(os.urandom(32)).decode())\""
            )
            logger.critical(error_msg)
            raise RuntimeError(error_msg)
        
        logger.info("✅ Master encryption key loaded and validated successfully")
        return master_key
        
    except Exception as e:
        error_msg = (
            f"CRITICAL SECURITY ERROR: Failed to decode INMUFACIL_MASTER_KEY. "
            f"Error: {str(e)}. "
            f"Please ensure the key is valid base64-encoded 32 bytes."
        )
        logger.critical(error_msg)
        raise RuntimeError(error_msg)


# ============================================================================
# @Shield - AES-256-GCM Encryption Functions
# ============================================================================

def encrypt_data(plaintext: str) -> str:
    """
    Encrypt sensitive data using AES-256-GCM.
    
    Args:
        plaintext: Data to encrypt (e.g., DNI number, phone)
        
    Returns:
        Base64-encoded string containing IV + ciphertext + tag
        Format: base64(iv || ciphertext || tag)
        
    Security Notes:
    - Uses AES-256-GCM for authenticated encryption
    - Generates unique 12-byte IV per encryption
    - Provides integrity verification (prevents tampering)
    - Safe to store in database as string
    
    Example:
        >>> encrypted = encrypt_data("12345678A")
        >>> # Returns: "rKz8Fg3h2k...base64..." (different each time)
    """
    if not plaintext:
        return ""
    
    # Get master key
    master_key = get_master_key()
    
    # Create AES-GCM cipher
    aesgcm = AESGCM(master_key)
    
    # Generate random 12-byte IV (nonce)
    iv = os.urandom(12)
    
    # Encrypt with associated data (AD) for additional context
    associated_data = b"inmufacil-vault-v1"
    ciphertext = aesgcm.encrypt(
        iv,
        plaintext.encode('utf-8'),
        associated_data
    )
    
    # Combine IV + ciphertext and encode as base64
    # Format: iv (12 bytes) || ciphertext || tag (16 bytes, included in ciphertext)
    encrypted_data = iv + ciphertext
    encoded = base64.b64encode(encrypted_data).decode('utf-8')
    
    logger.debug(f"🔒 Data encrypted (length: {len(plaintext)} -> {len(encoded)})")
    return encoded


def decrypt_data(encrypted: str) -> str:
    """
    Decrypt data encrypted with encrypt_data().
    
    Args:
        encrypted: Base64-encoded encrypted data
        
    Returns:
        Decrypted plaintext string
        
    Security Notes:
    - Verifies integrity using GCM authentication tag
    - Raises exception if data has been tampered with
    - Safe against padding oracle attacks (GCM mode)
    
    Raises:
        ValueError: If decryption fails (wrong key or tampered data)
        
    Example:
        >>> decrypted = decrypt_data(encrypted_dni)
        >>> # Returns: "12345678A"
    """
    if not encrypted:
        return ""
    
    try:
        # Decode from base64
        encrypted_data = base64.b64decode(encrypted)
        
        # Extract IV (first 12 bytes) and ciphertext (rest)
        iv = encrypted_data[:12]
        ciphertext = encrypted_data[12:]
        
        # Get master key
        master_key = get_master_key()
        
        # Create AES-GCM cipher
        aesgcm = AESGCM(master_key)
        
        # Decrypt with associated data verification
        associated_data = b"inmufacil-vault-v1"
        plaintext = aesgcm.decrypt(iv, ciphertext, associated_data)
        
        decrypted = plaintext.decode('utf-8')
        logger.debug(f"🔓 Data decrypted successfully")
        return decrypted
        
    except Exception as e:
        logger.error(f"❌ Decryption failed: {str(e)}")
        raise ValueError("Failed to decrypt data - data may be corrupted or key is incorrect")


# ============================================================================
# @Shield - Utility Functions
# ============================================================================

def encrypt_if_not_empty(value: Optional[str]) -> Optional[str]:
    """
    Encrypt value only if it's not None or empty.
    
    Args:
        value: String to encrypt or None
        
    Returns:
        Encrypted string or None
    """
    if value:
        return encrypt_data(value)
    return None


def decrypt_if_not_empty(value: Optional[str]) -> Optional[str]:
    """
    Decrypt value only if it's not None or empty.
    
    Args:
        value: Encrypted string or None
        
    Returns:
        Decrypted string or None
    """
    if value:
        return decrypt_data(value)
    return None


# ============================================================================
# @Watcher - Startup Validation
# ============================================================================

def validate_encryption_setup() -> bool:
    """
    Validate that encryption is properly configured.
    
    Returns:
        True if encryption is working correctly
        
    Security Notes:
    - Tests encryption/decryption round-trip
    - Verifies IV uniqueness
    - Should be called on application startup
    - Will raise RuntimeError if master key is missing/invalid
    
    @Watcher: Called during app startup for fail-safe validation
    """
    try:
        # Test 1: Master key validation (will raise if invalid)
        master_key = get_master_key()
        logger.info(f"✅ Master key validated: {len(master_key)} bytes")
        
        # Test 2: Encryption/decryption round-trip
        test_data = "TEST_DATA_12345"
        encrypted = encrypt_data(test_data)
        decrypted = decrypt_data(encrypted)
        
        if decrypted != test_data:
            logger.error("❌ Encryption validation failed: round-trip mismatch")
            return False
        
        # Test 3: IV uniqueness
        encrypted1 = encrypt_data(test_data)
        encrypted2 = encrypt_data(test_data)
        
        if encrypted1 == encrypted2:
            logger.error("❌ Encryption validation failed: IV not unique")
            return False
        
        logger.info("✅ Encryption system validated successfully")
        logger.info("🔐 VAULT ACTIVATED - All security checks passed")
        return True
        
    except Exception as e:
        logger.error(f"❌ Encryption validation failed: {str(e)}")
        raise  # Re-raise to prevent app startup


# ============================================================================
# @Shield - Key Rotation Support (Future)
# ============================================================================

def rotate_master_key(old_key_b64: str, new_key_b64: str) -> bool:
    """
    Rotate the master encryption key.
    
    Args:
        old_key_b64: Current master key (base64)
        new_key_b64: New master key (base64)
        
    Returns:
        True if rotation successful
        
    Security Notes:
    - This function is for future implementation
    - Requires re-encrypting all encrypted data in database
    - Should be done during maintenance window
    - Backup database before rotation
    
    TODO: Implement in future mission
    """
    logger.warning("⚠️  Key rotation not yet implemented")
    return False
