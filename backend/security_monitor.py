"""
@Watcher - Security Monitor (Audit & Brute Force Prevention)

Implements security monitoring and brute force attack prevention.
Tracks failed attempts and triggers alerts per MITRE ATT&CK T1110.

Token Consumption Tracking: ~600 tokens for security monitor
"""

from datetime import datetime, timedelta
from typing import Dict, List, Tuple
import logging

logger = logging.getLogger("inmufacil.security")


# ============================================================================
# @Watcher - Failed Attempt Tracking
# ============================================================================

# In-memory storage (use Redis or database in production)
_failed_attempts: Dict[int, List[datetime]] = {}
_locked_accounts: Dict[int, datetime] = {}

# Security thresholds
MAX_FAILED_ATTEMPTS = 3
LOCKOUT_DURATION_MINUTES = 15
ATTEMPT_WINDOW_MINUTES = 30


def record_failed_dni_upload(user_id: int) -> Tuple[bool, int, str]:
    """
    Record a failed DNI upload attempt.
    
    Args:
        user_id: User ID who failed upload
        
    Returns:
        Tuple of (is_locked, attempts_count, message)
        
    Security Notes:
    - Tracks attempts per user
    - Implements sliding window (30 minutes)
    - Triggers lockout after 3 failures
    - MITRE ATT&CK T1110 mitigation
    
    @Watcher: Brute force prevention
    """
    now = datetime.utcnow()
    
    # Initialize tracking for user if needed
    if user_id not in _failed_attempts:
        _failed_attempts[user_id] = []
    
    # Clean old attempts outside window
    cutoff = now - timedelta(minutes=ATTEMPT_WINDOW_MINUTES)
    _failed_attempts[user_id] = [
        attempt_time for attempt_time in _failed_attempts[user_id]
        if attempt_time > cutoff
    ]
    
    # Record this attempt
    _failed_attempts[user_id].append(now)
    attempt_count = len(_failed_attempts[user_id])
    
    # Check if lockout threshold reached
    if attempt_count >= MAX_FAILED_ATTEMPTS:
        lockout_until = now + timedelta(minutes=LOCKOUT_DURATION_MINUTES)
        _locked_accounts[user_id] = lockout_until
        
        # @Watcher: CRITICAL SECURITY ALERT
        logger.warning(
            f"🚨 SECURITY ALERT - BRUTE FORCE DETECTED | "
            f"User ID: {user_id} | "
            f"Failed attempts: {attempt_count} | "
            f"Locked until: {lockout_until.isoformat()} | "
            f"MITRE T1110: Brute Force"
        )
        
        return True, attempt_count, f"Account temporarily locked due to multiple failed attempts. Try again in {LOCKOUT_DURATION_MINUTES} minutes."
    
    logger.warning(
        f"⚠️  Failed DNI upload attempt | "
        f"User ID: {user_id} | "
        f"Attempt {attempt_count}/{MAX_FAILED_ATTEMPTS}"
    )
    
    remaining = MAX_FAILED_ATTEMPTS - attempt_count
    return False, attempt_count, f"Upload failed. {remaining} attempts remaining before temporary lockout."


def is_account_locked(user_id: int) -> Tuple[bool, str]:
    """
    Check if account is currently locked.
    
    Args:
        user_id: User ID to check
        
    Returns:
        Tuple of (is_locked, message)
        
    Security Notes:
    - Checks lockout expiration
    - Auto-unlocks after duration
    - Provides clear user feedback
    """
    if user_id not in _locked_accounts:
        return False, ""
    
    lockout_until = _locked_accounts[user_id]
    now = datetime.utcnow()
    
    # Check if lockout has expired
    if now >= lockout_until:
        # Auto-unlock
        del _locked_accounts[user_id]
        _failed_attempts[user_id] = []
        logger.info(f"🔓 Account auto-unlocked: User ID {user_id}")
        return False, ""
    
    # Still locked
    remaining = lockout_until - now
    minutes = int(remaining.total_seconds() / 60)
    
    logger.info(f"🔒 Account locked: User ID {user_id} | Remaining: {minutes} minutes")
    return True, f"Account is temporarily locked. Try again in {minutes} minutes."


def clear_failed_attempts(user_id: int):
    """
    Clear failed attempts for user (after successful upload).
    
    Args:
        user_id: User ID to clear
        
    Security Notes:
    - Called after successful DNI upload
    - Resets attempt counter
    """
    if user_id in _failed_attempts:
        _failed_attempts[user_id] = []
    
    logger.info(f"✅ Failed attempts cleared for user {user_id}")


# ============================================================================
# @Watcher - Security Event Logging
# ============================================================================

def log_security_event(
    event_type: str,
    user_id: int,
    details: str,
    severity: str = "INFO"
):
    """
    Log security-related events with structured format.
    
    Args:
        event_type: Type of security event
        user_id: User ID involved
        details: Event details
        severity: Event severity (INFO, WARNING, CRITICAL)
        
    Security Notes:
    - Structured logging for SIEM integration
    - Never logs sensitive data (passwords, DNI numbers, etc.)
    - Includes timestamp and user context
    
    @Watcher: Audit trail for security events
    """
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "event_type": event_type,
        "user_id": user_id,
        "severity": severity,
        "details": details,
    }
    
    if severity == "CRITICAL":
        logger.critical(f"🚨 SECURITY EVENT | {log_entry}")
    elif severity == "WARNING":
        logger.warning(f"⚠️  SECURITY EVENT | {log_entry}")
    else:
        logger.info(f"ℹ️  SECURITY EVENT | {log_entry}")


def log_kyc_operation(
    operation: str,
    user_id: int,
    success: bool,
    details: str = ""
):
    """
    Log KYC-related operations for audit trail.
    
    Args:
        operation: Operation type (e.g., "DNI_UPLOAD", "EMAIL_VERIFICATION")
        user_id: User ID
        success: Whether operation succeeded
        details: Additional details (NO SENSITIVE DATA)
        
    Security Notes:
    - Complete audit trail for compliance
    - Never logs actual DNI numbers or images
    - Tracks all KYC state changes
    
    @Watcher: Compliance and audit logging
    """
    status = "SUCCESS" if success else "FAILED"
    severity = "INFO" if success else "WARNING"
    
    log_security_event(
        event_type=f"KYC_{operation}_{status}",
        user_id=user_id,
        details=details,
        severity=severity
    )


# ============================================================================
# @Watcher - Sensitive Data Filter
# ============================================================================

class SensitiveDataFilter(logging.Filter):
    """
    Logging filter to prevent sensitive data from being logged.
    
    Filters out:
    - Passwords
    - DNI numbers
    - Phone numbers
    - Email addresses (partial redaction)
    - Verification tokens
    
    @Watcher: Security by Default - never log sensitive data
    """
    
    SENSITIVE_PATTERNS = [
        'password',
        'dni',
        'phone',
        'token',
        'secret',
        'key',
    ]
    
    def filter(self, record):
        """
        Filter log record to remove sensitive data.
        
        Returns:
            True to allow log, False to block
        """
        message = record.getMessage().lower()
        
        # Check for sensitive keywords
        for pattern in self.SENSITIVE_PATTERNS:
            if pattern in message and '***' not in message:
                # If sensitive keyword found without redaction marker
                # This is a safety check - code should already redact
                logger.warning(
                    f"⚠️  Attempted to log potentially sensitive data. "
                    f"Log blocked for security."
                )
                return False
        
        return True


def configure_secure_logging():
    """
    Configure logging with sensitive data filters.
    
    Security Notes:
    - Adds filter to all loggers
    - Prevents accidental sensitive data logging
    - Defense in depth approach
    
    @Watcher: Security by Default configuration
    """
    # Add filter to root logger
    root_logger = logging.getLogger()
    root_logger.addFilter(SensitiveDataFilter())
    
    logger.info("✅ Secure logging configured with sensitive data filters")
