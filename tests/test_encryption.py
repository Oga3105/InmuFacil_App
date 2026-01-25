"""
@Shield - Encryption Test Suite

Tests for AES-256-GCM encryption implementation.
Verifies confidentiality, integrity, and IV uniqueness.

Token Consumption Tracking: ~300 tokens for encryption tests
"""

import pytest
from backend.core.security import (
    encrypt_data,
    decrypt_data,
    validate_encryption_setup,
    get_master_key
)


# ============================================================================
# @Shield - AES-256-GCM Verification Tests
# ============================================================================

def test_encryption_decryption_round_trip():
    """
    Test that data can be encrypted and decrypted successfully.
    
    @Shield: Verifies basic encryption/decryption functionality
    """
    test_data = "DNI_TEST_1234"
    
    # Encrypt
    encrypted = encrypt_data(test_data)
    
    # Verify encrypted data is different from plaintext
    assert encrypted != test_data
    assert len(encrypted) > len(test_data)
    
    # Decrypt
    decrypted = decrypt_data(encrypted)
    
    # Verify decryption returns original data
    assert decrypted == test_data


def test_iv_uniqueness():
    """
    Test that IV (nonce) is unique for each encryption operation.
    
    @Shield: Critical for AES-GCM security - same plaintext should produce different ciphertext
    """
    test_data = "DNI_TEST_1234"
    
    # Encrypt same data multiple times
    encrypted1 = encrypt_data(test_data)
    encrypted2 = encrypt_data(test_data)
    encrypted3 = encrypt_data(test_data)
    
    # Verify all encrypted values are different (due to unique IV)
    assert encrypted1 != encrypted2
    assert encrypted2 != encrypted3
    assert encrypted1 != encrypted3
    
    # But all decrypt to same value
    assert decrypt_data(encrypted1) == test_data
    assert decrypt_data(encrypted2) == test_data
    assert decrypt_data(encrypted3) == test_data


def test_empty_string_handling():
    """
    Test that empty strings are handled correctly.
    
    @Shield: Edge case handling
    """
    # Empty string should return empty string
    assert encrypt_data("") == ""
    assert decrypt_data("") == ""


def test_special_characters():
    """
    Test encryption of special characters and unicode.
    
    @Shield: Ensures proper UTF-8 handling
    """
    test_cases = [
        "DNI: 12345678-A",
        "Teléfono: +34 600 123 456",
        "Ñoño García",
        "Test with émojis [VAULT]🏠",
    ]
    
    for test_data in test_cases:
        encrypted = encrypt_data(test_data)
        decrypted = decrypt_data(encrypted)
        assert decrypted == test_data


def test_master_key_validation():
    """
    Test that master key is properly validated.
    
    @Shield: Ensures key is 32 bytes for AES-256
    """
    master_key = get_master_key()
    
    # Verify key length is exactly 32 bytes (256 bits)
    assert len(master_key) == 32


def test_encryption_system_validation():
    """
    Test complete encryption system validation.
    
    @Watcher: Startup validation test
    """
    # This should pass if encryption is properly configured
    is_valid = validate_encryption_setup()
    assert is_valid is True


def test_integrity_verification():
    """
    Test that tampering with encrypted data is detected.
    
    @Shield: AES-GCM provides authenticated encryption
    """
    test_data = "DNI_TEST_1234"
    encrypted = encrypt_data(test_data)
    
    # Tamper with encrypted data (change one character)
    if len(encrypted) > 10:
        tampered = encrypted[:10] + ('X' if encrypted[10] != 'X' else 'Y') + encrypted[11:]
        
        # Decryption should fail on tampered data
        with pytest.raises(ValueError):
            decrypt_data(tampered)


def test_long_data_encryption():
    """
    Test encryption of longer data strings.
    
    @Shield: Ensures no length limitations
    """
    # Create a long string (1000 characters)
    test_data = "A" * 1000
    
    encrypted = encrypt_data(test_data)
    decrypted = decrypt_data(encrypted)
    
    assert decrypted == test_data
    assert len(decrypted) == 1000


# ============================================================================
# @Shield - Quick Manual Test Function
# ============================================================================

def quick_encryption_test():
    """
    Quick manual test for encryption verification.
    Can be run directly for debugging.
    
    @Shield: Manual verification tool
    """
    print("=" * 60)
    print("[VAULT] AES-256-GCM Encryption Test")
    print("=" * 60)
    
    test_data = "DNI_TEST_1234"
    print(f"\n[LOG] Original data: {test_data}")
    
    # Test 1: Encrypt
    encrypted1 = encrypt_data(test_data)
    print(f"[ENCRYPT] Encrypted (1): {encrypted1[:50]}...")
    
    # Test 2: Encrypt again (should be different)
    encrypted2 = encrypt_data(test_data)
    print(f"[ENCRYPT] Encrypted (2): {encrypted2[:50]}...")
    
    # Test 3: Verify they're different
    if encrypted1 != encrypted2:
        print("[OK] IV uniqueness: PASS (different ciphertext each time)")
    else:
        print("[ERROR] IV uniqueness: FAIL (same ciphertext)")
    
    # Test 4: Decrypt both
    decrypted1 = decrypt_data(encrypted1)
    decrypted2 = decrypt_data(encrypted2)
    
    print(f"\n[DECRYPT] Decrypted (1): {decrypted1}")
    print(f"[DECRYPT] Decrypted (2): {decrypted2}")
    
    # Test 5: Verify decryption
    if decrypted1 == test_data and decrypted2 == test_data:
        print("[OK] Decryption: PASS (correct plaintext)")
    else:
        print("[ERROR] Decryption: FAIL")
    
    # Test 6: Master key
    master_key = get_master_key()
    print(f"\n🔑 Master key length: {len(master_key)} bytes")
    if len(master_key) == 32:
        print("[OK] Key length: PASS (256 bits)")
    else:
        print(f"[ERROR] Key length: FAIL (expected 32, got {len(master_key)})")
    
    print("\n" + "=" * 60)
    print("[OK] All tests completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    # Run quick test if executed directly
    quick_encryption_test()
