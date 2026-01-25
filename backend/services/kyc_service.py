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
import cv2
import numpy as np
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
    Redact sensitive information using intelligent document detection (Pure OpenCV).
    
    Args:
        input_path: Path to original document image
        output_path: Path to save redacted image
        document_type: Type of document (DNI, NIE, or PASSPORT)
        
    Returns:
        True if redaction successful, False otherwise
        
    Detection Strategy:
    1. Use OpenCV to detect document boundaries (contour detection)
    2. Apply redaction zones RELATIVE to detected document, not full image
    3. Preserve face area (top-left of detected document)
    4. Pure OpenCV implementation (no Pillow dependency)
    
    Redaction Zones (relative to detected document):
    - **DNI/NIE**: MRZ (bottom 25% of doc), Signature (lower-center of doc)
    - **Passport**: MRZ (bottom 30% of doc), Signature (lower-center of doc)
    
    @Jules: Lean implementation with OpenCV only
    """
    try:
        # Step 1: Load image with OpenCV
        logger.info(f"[IMAGE] Detecting document boundaries...")
        
        img = cv2.imread(input_path)
        if img is None:
            logger.error(f"[ERROR] Could not read image with OpenCV")
            return False
        
        full_height, full_width = img.shape[:2]
        
        # Step 2: Detect document boundaries
        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Edge detection
        edges = cv2.Canny(blurred, 50, 150)
        
        # Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Find largest contour (likely the document)
        doc_x, doc_y, doc_w, doc_h = 0, 0, full_width, full_height
        
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            x, y, w, h = cv2.boundingRect(largest_contour)
            
            # Validate detection
            area_ratio = (w * h) / (full_width * full_height)
            aspect_ratio = w / h if h > 0 else 0
            
            if area_ratio > 0.4 and 1.2 < aspect_ratio < 2.0:
                doc_x, doc_y, doc_w, doc_h = x, y, w, h
                logger.info(f"[OK] Document detected: {doc_w}x{doc_h} at ({doc_x}, {doc_y})")
                logger.info(f"[OK] Area: {area_ratio:.2%}, Aspect: {aspect_ratio:.2f}")
            else:
                logger.warning(f"[WARNING] Detection failed validation, using center 80%")
                margin_x = int(full_width * 0.10)
                margin_y = int(full_height * 0.10)
                doc_x, doc_y = margin_x, margin_y
                doc_w, doc_h = full_width - 2 * margin_x, full_height - 2 * margin_y
        else:
            logger.warning(f"[WARNING] No contours found, using full image")
        
        logger.info(f"[IMAGE] Processing {document_type} document")
        logger.info(f"[IMAGE] Document bounds: x={doc_x}, y={doc_y}, w={doc_w}, h={doc_h}")
        
        # Step 3: Apply redaction zones using cv2.rectangle (Pure OpenCV)
        if document_type in ["DNI", "NIE"]:
            # DNI/NIE: MRZ at bottom 25% of document
            mrz_start_y = doc_y + int(doc_h * 0.75)
            mrz_end_y = doc_y + doc_h
            cv2.rectangle(img, (doc_x, mrz_start_y), (doc_x + doc_w, mrz_end_y), (0, 0, 0), -1)
            
            # Signature: Lower-center of document
            sig_start_x = doc_x + int(doc_w * 0.50)
            sig_end_x = doc_x + int(doc_w * 0.75)
            sig_start_y = doc_y + int(doc_h * 0.60)
            sig_end_y = doc_y + int(doc_h * 0.75)
            cv2.rectangle(img, (sig_start_x, sig_start_y), (sig_end_x, sig_end_y), (0, 0, 0), -1)
            
            logger.info(f"[OK] DNI/NIE redaction: MRZ + Signature (OpenCV rectangles)")
            
        elif document_type == "PASSPORT":
            # Passport: MRZ at bottom 30% of document
            mrz_start_y = doc_y + int(doc_h * 0.70)
            mrz_end_y = doc_y + doc_h
            cv2.rectangle(img, (doc_x, mrz_start_y), (doc_x + doc_w, mrz_end_y), (0, 0, 0), -1)
            
            # Signature: Lower-center
            sig_start_x = doc_x + int(doc_w * 0.40)
            sig_end_x = doc_x + int(doc_w * 0.70)
            sig_start_y = doc_y + int(doc_h * 0.55)
            sig_end_y = doc_y + int(doc_h * 0.70)
            cv2.rectangle(img, (sig_start_x, sig_start_y), (sig_end_x, sig_end_y), (0, 0, 0), -1)
            
            logger.info(f"[OK] Passport redaction: MRZ + Signature (OpenCV rectangles)")
        
        # Step 4: Save with cv2.imwrite (Pure OpenCV)
        success = cv2.imwrite(output_path, img)
        if not success:
            logger.error(f"[ERROR] Failed to save redacted image")
            return False
        
        logger.info(f"[OK] Document redacted successfully: {output_path}")
        logger.info(f"[OK] Face area preserved (top 50% of document untouched)")
        return True
        
    except Exception as e:
        logger.error(f"[ERROR] Intelligent redaction failed: {str(e)}")
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
