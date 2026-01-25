"""
@Jules - KYC Service (Secure Document Processing)
@Shield - MIME Type Validation & File Security

Implements secure DNI image processing with automatic redaction.
Validates file types to prevent malicious uploads.

Security Features:
- MIME type validation (prevents script injection)
- File size limits (max 5MB)
- Image format validation (JPEG, PNG only)
- Automatic redaction of sensitive zones
- Secure random filenames

Token Consumption Tracking: ~900 tokens for KYC service
"""

import os
import secrets
import mimetypes
import hashlib
from pathlib import Path
from typing import Tuple, Optional, Dict
from PIL import Image, ImageDraw
import logging

logger = logging.getLogger("inmufacil.kyc")


# ============================================================================
# @Shield - File Validation Constants
# ============================================================================

ALLOWED_MIME_TYPES = {
    'image/jpeg',
    'image/jpg',
    'image/png',
}

ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png'}

MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB in bytes

# Upload directory (should be outside web root in production)
UPLOAD_DIR = Path("uploads/dni_documents")


# ============================================================================
# @Watcher - File Hashing for Audit Trail
# ============================================================================

def calculate_file_hash(file_path: str) -> str:
    """
    Calculate SHA-256 hash of file for integrity verification.
    
    Args:
        file_path: Path to file
        
    Returns:
        Hexadecimal SHA-256 hash
        
    Security Notes:
    - Used for audit trail (not for sensitive data)
    - Verifies file integrity
    - Detects tampering or corruption
    
    @Watcher: Audit logging without exposing content
    """
    sha256_hash = hashlib.sha256()
    
    with open(file_path, "rb") as f:
        # Read file in chunks to handle large files
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    
    file_hash = sha256_hash.hexdigest()
    logger.debug(f"[HASH] File hash calculated: {file_hash[:16]}...")
    return file_hash


# ============================================================================
# @Shield - MIME Type Validation
# ============================================================================

def validate_file_type(file_path: str, original_filename: str) -> Tuple[bool, str]:
    """
    Validate file type using multiple methods to prevent bypass.
    
    Args:
        file_path: Path to uploaded file
        original_filename: Original filename from upload
        
    Returns:
        Tuple of (is_valid, error_message)
        
    Security Notes:
    - Checks file extension
    - Validates MIME type from content (not just extension)
    - Prevents malicious files disguised as images
    - Defense in depth approach
    
    @Shield: Multi-layer validation prevents bypass attacks
    """
    # Check 1: File extension
    file_ext = Path(original_filename).suffix.lower()
    if file_ext not in ALLOWED_EXTENSIONS:
        logger.warning(f"[BLOCKED] Invalid file extension: {file_ext}")
        return False, f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
    
    # Check 2: MIME type from content
    try:
        # Try to open as image (will fail if not a real image)
        with Image.open(file_path) as img:
            # Get format from PIL
            image_format = img.format
            if image_format not in ['JPEG', 'PNG']:
                logger.warning(f"[BLOCKED] Invalid image format: {image_format}")
                return False, "Invalid image format. Only JPEG and PNG are allowed."
            
            logger.info(f"[OK] File validated: {image_format} image")
            return True, ""
            
    except Exception as e:
        logger.error(f"[ERROR] File validation failed: {str(e)}")
        return False, "File is not a valid image or is corrupted."


def validate_file_size(file_path: str) -> Tuple[bool, str]:
    """
    Validate file size is within limits.
    
    Args:
        file_path: Path to file
        
    Returns:
        Tuple of (is_valid, error_message)
        
    Security Notes:
    - Prevents DoS via large file uploads
    - 5MB limit is reasonable for DNI images
    """
    file_size = os.path.getsize(file_path)
    
    if file_size > MAX_FILE_SIZE:
        size_mb = file_size / (1024 * 1024)
        logger.warning(f"[BLOCKED] File too large: {size_mb:.2f}MB")
        return False, f"File too large ({size_mb:.2f}MB). Maximum size is 5MB."
    
    logger.info(f"[OK] File size OK: {file_size / 1024:.2f}KB")
    return True, ""


# ============================================================================
# @Jules - Adaptive Document Image Redaction
# ============================================================================

def redact_document_image(input_path: str, output_path: str, document_type: str = "DNI") -> bool:
    """
    Redact sensitive information from identity document with adaptive zones.
    
    Args:
        input_path: Path to original document image
        output_path: Path to save redacted image
        document_type: Type of document (DNI, NIE, or PASSPORT)
        
        document_type: Type of document (DNI, NIE, or PASSPORT)
        
    Returns:
        True if redaction successful, False otherwise
        
    Redaction Strategy (Percentage-based):
    - DNI/NIE: 30% bottom (MRZ) + 10% center height (signature)
    - Passport: 40% bottom (MRZ lines) + signature zone (30-40% from bottom)
    - Orientation detection: Adjusts zones if image is vertical (height > width)
    - Face protection: Top 40% never redacted
    
    @Jules: Adaptive privacy redaction with orientation detection
    """
    try:
        # Open image
        img = Image.open(input_path)
        width, height = img.size
        draw = ImageDraw.Draw(img)
        
        # Detect orientation
        is_vertical = height > width
        logger.info(f"[IMAGE] Document orientation: {'Vertical' if is_vertical else 'Horizontal'} ({width}x{height})")
        
        # Define redaction zones based on document type
        if document_type in ["DNI", "NIE"]:
            # DNI/NIE: 30% bottom for MRZ + center signature block
            if is_vertical:
                # Vertical: Adjust proportionally
                mrz_start_y = int(height * 0.70)  # Start at 70% down
                mrz_end_y = height  # To bottom
                
                # Signature zone: 40-50% from top (center area)
                sig_start_y = int(height * 0.40)
                sig_end_y = int(height * 0.50)
                sig_start_x = int(width * 0.10)
                sig_end_x = int(width * 0.90)
            else:
                # Horizontal: Standard zones
                mrz_start_y = int(height * 0.70)
                mrz_end_y = height
                
                # Signature zone: Center 10% height
                sig_start_y = int(height * 0.45)
                sig_end_y = int(height * 0.55)
                sig_start_x = int(width * 0.10)
                sig_end_x = int(width * 0.40)
            
            # Draw MRZ redaction (full width, bottom 30%)
            draw.rectangle([0, mrz_start_y, width, mrz_end_y], fill='black')
            
            # Draw signature redaction
            draw.rectangle([sig_start_x, sig_start_y, sig_end_x, sig_end_y], fill='black')
            
            logger.info(f"[OK] DNI/NIE redaction applied: MRZ zone + signature block")
            
        elif document_type == "PASSPORT":
            # Passport: 40% bottom for MRZ lines + signature zone above
            if is_vertical:
                # Vertical: Adjust proportionally
                mrz_start_y = int(height * 0.60)  # Start at 60% down (40% coverage)
                mrz_end_y = height
                
                # Signature zone: 50-60% from top
                sig_start_y = int(height * 0.50)
                sig_end_y = int(height * 0.60)
                sig_start_x = int(width * 0.10)
                sig_end_x = int(width * 0.90)
            else:
                # Horizontal: Standard zones
                mrz_start_y = int(height * 0.60)
                mrz_end_y = height
                
                # Signature zone: 30-40% from bottom
                sig_start_y = int(height * 0.60)
                sig_end_y = int(height * 0.70)
                sig_start_x = int(width * 0.10)
                sig_end_x = int(width * 0.50)
            
            # Draw MRZ redaction (full width, bottom 40%)
            draw.rectangle([0, mrz_start_y, width, mrz_end_y], fill='black')
            
            # Draw signature redaction
            draw.rectangle([sig_start_x, sig_start_y, sig_end_x, sig_end_y], fill='black')
            
            logger.info(f"[OK] Passport redaction applied: Extended MRZ zone + signature")
        
        else:
            logger.warning(f"[WARNING] Unknown document type: {document_type}, using DNI defaults")
            # Fallback to DNI redaction
            mrz_start_y = int(height * 0.70)
            draw.rectangle([0, mrz_start_y, width, height], fill='black')
        
        # Save redacted image
        img.save(output_path)
        logger.info(f"[OK] Document image redacted successfully: {output_path}")
        return True
        
    except Exception as e:
        logger.error(f"[ERROR] Document redaction failed: {str(e)}")
        return False


# Backward compatibility alias
def redact_dni_image(input_path: str, output_path: str) -> bool:
    """
    Legacy function for backward compatibility.
    Redirects to redact_document_image with DNI type.
    """
    return redact_document_image(input_path, output_path, document_type="DNI")


def redact_dni(image_path: str) -> Tuple[bool, Optional[str], Optional[Dict[str, str]]]:
    """
    Main DNI redaction function with OCR simulation.
    
    Args:
        image_path: Path to original DNI image
        
    Returns:
        Tuple of (success, redacted_image_path, extracted_data)
        
    Security Flow:
    1. Simulate OCR data extraction
    2. Redact sensitive zones
    3. Return redacted image and extracted data for encryption
    
    @Jules: Complete redaction pipeline
    @Shield: Data extraction for encryption
    """
    try:
        # Generate output path
        output_path = image_path.replace('.', '_redacted.')
        
        # Redact image
        success = redact_dni_image(image_path, output_path)
        
        if not success:
            return False, None, None
        
        # Simulate OCR data extraction (in production, use real OCR)
        # This data would be encrypted before storage
        extracted_data = {
            "dni_number": "SIMULATED_DNI_12345678A",  # Would come from OCR
            "full_name": "SIMULATED_NAME",  # Would come from OCR
            "birth_date": "SIMULATED_DATE",  # Would come from OCR
        }
        
        logger.info("[OK] DNI redaction and OCR simulation completed")
        return True, output_path, extracted_data
        
    except Exception as e:
        logger.error(f"[ERROR] DNI redaction failed: {str(e)}")
        return False, None, None


# ============================================================================
# @Shield - Secure Cleanup
# ============================================================================

def secure_delete_file(file_path: str) -> bool:
    """
    Securely delete file with verification.
    
    Args:
        file_path: Path to file to delete
        
    Returns:
        True if deletion successful and verified
        
    Security Notes:
    - Deletes original file immediately after processing
    - Verifies file no longer exists
    - "No se guarda lo que no se necesita" principle
    
    @Shield: Secure cleanup to minimize data exposure
    """
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            
            # Verify deletion
            if os.path.exists(file_path):
                logger.error(f"[ERROR] File still exists after deletion: {file_path}")
                return False
            
            logger.info(f"[DELETE]  File securely deleted: {file_path}")
            return True
        else:
            logger.debug(f"File already deleted: {file_path}")
            return True
            
    except Exception as e:
        logger.error(f"[ERROR] Secure deletion failed: {str(e)}")
        return False


# ============================================================================
# @Jules - Secure File Upload Processing
# ============================================================================

def generate_secure_filename(original_filename: str) -> str:
    """
    Generate secure random filename.
    
    Args:
        original_filename: Original uploaded filename
        
    Returns:
        Secure random filename with original extension
        
    Security Notes:
    - Uses cryptographically secure random
    - Prevents directory traversal attacks
    - Preserves file extension for compatibility
    """
    # Get file extension
    ext = Path(original_filename).suffix.lower()
    
    # Generate random filename (32 hex characters)
    random_name = secrets.token_hex(16)
    
    secure_filename = f"{random_name}{ext}"
    logger.debug(f"Generated secure filename: {secure_filename}")
    return secure_filename


async def process_dni_upload(
    file_path: str,
    original_filename: str,
    user_id: int
) -> Tuple[bool, str, Optional[str], Optional[str]]:
    """
    Process DNI image upload with validation and redaction.
    
    Args:
        file_path: Temporary path to uploaded file
        original_filename: Original filename
        user_id: User ID for organizing uploads
        
    Returns:
        Tuple of (success, message, saved_file_path, file_hash)
        
    Security Flow:
    1. Calculate file hash for audit
    2. Validate file size
    3. Validate file type (MIME)
    4. Redact sensitive zones
    5. Save with secure filename
    6. Delete original temporary file (verified)
    
    @Jules: Complete upload processing pipeline
    @Shield: Multi-layer security validation + secure cleanup
    @Watcher: File hashing for audit trail
    """
    file_hash = None
    
    try:
        # Step 1: Calculate file hash for audit (before any processing)
        file_hash = calculate_file_hash(file_path)
        logger.info(f"[HASH] File hash: {file_hash[:16]}... (for audit)")
        
        # Step 2: Validate file size
        is_valid, error = validate_file_size(file_path)
        if not is_valid:
            secure_delete_file(file_path)  # Clean up
            return False, error, None, file_hash
        
        # Step 3: Validate file type
        is_valid, error = validate_file_type(file_path, original_filename)
        if not is_valid:
            secure_delete_file(file_path)  # Clean up
            return False, error, None, file_hash
        
        # Step 4: Create user upload directory
        user_upload_dir = UPLOAD_DIR / str(user_id)
        user_upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Step 5: Generate secure filename
        secure_filename = generate_secure_filename(original_filename)
        output_path = user_upload_dir / secure_filename
        
        # Step 6: Redact DNI image
        success = redact_dni_image(file_path, str(output_path))
        if not success:
            secure_delete_file(file_path)  # Clean up
            return False, "Failed to process DNI image. Please try again.", None, file_hash
        
        # Step 7: Secure cleanup - delete original file
        cleanup_success = secure_delete_file(file_path)
        if not cleanup_success:
            logger.warning("[WARNING]  Original file cleanup verification failed")
        
        logger.info(f"[OK] DNI upload processed successfully for user {user_id}")
        return True, "DNI image uploaded and processed successfully.", str(output_path), file_hash
        
    except Exception as e:
        logger.error(f"[ERROR] DNI upload processing failed: {str(e)}")
        # Attempt cleanup on error
        secure_delete_file(file_path)
        return False, "An error occurred while processing your DNI. Please try again.", None, file_hash


# ============================================================================
# @Shield - Security Utilities
# ============================================================================

def ensure_upload_directory():
    """
    Ensure upload directory exists with proper permissions.
    
    Security Notes:
    - Creates directory if not exists
    - Should be outside web root in production
    - Set proper permissions (owner read/write only)
    """
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    logger.info(f"[DIR] Upload directory ready: {UPLOAD_DIR}")
