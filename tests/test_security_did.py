"""
@Watcher - Defense in Depth Security Tests (TDD)

Implements security tests for 3 Critical Layers:
1. Layer 4: Access (Brute Force Prevention)
2. Layer 2: Identity (Malicious File Uploads)
3. Layer 1: Perimeter (IDOR/Authorization)
"""

import pytest
from datetime import datetime, timedelta
from fastapi import HTTPException
from unittest.mock import MagicMock, patch

from backend.src.utils.security_monitor import (
    record_failed_dni_upload, 
    is_account_locked, 
    MAX_FAILED_ATTEMPTS,
    LOCKOUT_DURATION_MINUTES
)
# We will mock the validation function if it doesn't exist yet, or import it
# assuming it should be in backend.services.kyc_service or utils
from backend.src.services.kyc_service import validate_mime_type 

# ============================================================================
# Layer 4: Brute Force Prevention Tests
# ============================================================================

def test_brute_force_lockout_mechanism():
    """
    Test 1: User is locked out after MAX_FAILED_ATTEMPTS.
    """
    user_id = 999 
    # Reset state for this user (mocking internal state reset would be ideal, 
    # but for unit test we can rely on isolation or manual clear if globals used)
    # Ideally implementation uses Redis/DB, here it uses globals in memory
    from backend.src.utils.security_monitor import _failed_attempts, _locked_accounts
    _failed_attempts[user_id] = []
    if user_id in _locked_accounts:
        del _locked_accounts[user_id]
        
    # Attempt 1 -> OK
    is_locked, count, msg = record_failed_dni_upload(user_id)
    assert is_locked is False
    assert count == 1
    
    # Attempt 2 -> OK
    is_locked, count, msg = record_failed_dni_upload(user_id)
    assert is_locked is False
    assert count == 2
    
    # Attempt 3 -> LOCKOUT
    is_locked, count, msg = record_failed_dni_upload(user_id)
    assert is_locked is True
    assert count == 3
    assert "temporarily locked" in msg
    
    # Check status
    locked, _ = is_account_locked(user_id)
    assert locked is True


# ============================================================================
# Layer 2: Malicious File Upload (MIME Validation)
# ============================================================================

def test_mime_validation_rejects_fake_images():
    """
    Test 2: Renaming .exe to .jpg must fail MIME check.
    Uses 'python-magic' or similar verification.
    """
    # Create a fake file content that is definitely NOT an image (e.g., text/script)
    malicious_content = b"#!/bin/bash\nrm -rf /"
    
    # Mock UploadFile behavior
    class MockFile:
        def __init__(self, content, filename):
            self.file = MagicMock()
            self.file.read.return_value = content
            self.filename = filename
            self.content_type = "image/jpeg" # SPOOFED header
            
    fake_file = MockFile(malicious_content, "vacation.jpg")
    
    # Expect validation to FAIL despite the .jpg extension
    with pytest.raises(HTTPException) as exc:
        validate_mime_type(fake_file) # Function we expect to implement/exist
        
    assert exc.value.status_code == 400
    assert "Invalid file type" in str(exc.value.detail)


# ============================================================================
# Layer 1: IDOR (Insecure Direct Object Reference)
# ============================================================================

def test_idor_prevention_on_property_edit():
    """
    Test 3: User A cannot edit User B's property.
    """
    # This logic usually resides in `verify_property_ownership` dependency in routers
    from backend.src.routes.properties import verify_property_ownership
    
    # Mock DB Session
    mock_db = MagicMock()
    
    # Mock Property belonging to User B (ID=2)
    mock_property = MagicMock()
    mock_property.id = 100
    mock_property.owner_id = 2 
    
    mock_db.query.return_value.filter.return_value.first.return_value = mock_property
    
    # User A (ID=1) attempts access
    attacker_id = 1
    
    with pytest.raises(HTTPException) as exc:
        verify_property_ownership(mock_db, property_id=100, user_id=attacker_id)
        
    assert exc.value.status_code == 403
    assert "Not authorized" in str(exc.value.detail)

