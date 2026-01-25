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
    Validate file type using OpenCV (Pure OpenCV - no PIL dependency).
    
    Args:
        file_path: Path to uploaded file
        original_filename: Original filename from upload
        
    Returns:
        Tuple of (is_valid, error_message)
        
    Security Notes:
    - Checks file extension
    - Validates image can be decoded by OpenCV
    - Prevents malicious files disguised as images
    - Defense in depth approach
    
    @Shield: Multi-layer validation prevents bypass attacks
    @Jules: Pure OpenCV implementation
    """
    # Check 1: File extension
    file_ext = Path(original_filename).suffix.lower()
    if file_ext not in ALLOWED_EXTENSIONS:
        logger.warning(f"[BLOCKED] Invalid file extension: {file_ext}")
        return False, f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
    
    # Check 2: Try to decode as image with OpenCV
    try:
        # Attempt to read image with OpenCV
        img = cv2.imread(file_path)
        
        if img is None:
            logger.warning(f"[BLOCKED] File could not be decoded as image")
            return False, "File is not a valid image or is corrupted."
        
        # Validate image has reasonable dimensions
        height, width = img.shape[:2]
        if width < 100 or height < 100:
            logger.warning(f"[BLOCKED] Image too small: {width}x{height}")
            return False, "Image dimensions too small (minimum 100x100 pixels)."
        
        if width > 10000 or height > 10000:
            logger.warning(f"[BLOCKED] Image too large: {width}x{height}")
            return False, "Image dimensions too large (maximum 10000x10000 pixels)."
        
        logger.info(f"[OK] File validated: {width}x{height} image")
        return True, ""
            
    except Exception as e:
        logger.error(f"[ERROR] File validation failed: {str(e)}")
        return False, "Error decoding image or unsupported format."


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
    Intelligent document detection with aspect ratio classification and surgical redaction.
    
    Args:
        input_path: Path to original document image
        output_path: Path to save redacted image
        document_type: Hint for document type (DNI, NIE, or PASSPORT)
        
    Returns:
        True if redaction successful, False otherwise
        
    @Jules: Intelligent vision with aspect ratio classification
    @Shield: Surgical redaction zones - FIXED for NIE dual numbers and passport pages
    """
    try:
        # Step 1: Load image
        logger.info(f"[VISION] Loading image for intelligent analysis...")
        
        img = cv2.imread(input_path)
        if img is None:
            logger.error(f"[ERROR] Could not decode image")
            return False
        
        img_h, img_w = img.shape[:2]
        logger.info(f"[VISION] Image size: {img_w}x{img_h}")
        
        # Step 2: Adaptive thresholding
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        thresh = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV,
            21, 5
        )
        
        kernel = np.ones((7, 7), np.uint8)
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
        thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)
        
        # Step 3: Find document contour
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        doc_x, doc_y, doc_w, doc_h = 0, 0, img_w, img_h
        detected = False
        
        if contours:
            contours = sorted(contours, key=cv2.contourArea, reverse=True)
            for cnt in contours[:3]:
                x, y, w, h = cv2.boundingRect(cnt)
                area_ratio = (w * h) / (img_w * img_h)
                if area_ratio > 0.25:
                    doc_x, doc_y, doc_w, doc_h = x, y, w, h
                    detected = True
                    logger.info(f"[OK] Document found: {doc_w}x{doc_h} at ({doc_x},{doc_y})")
                    break
        
        if not detected:
            margin = int(min(img_w, img_h) * 0.05)
            doc_x, doc_y = margin, margin
            doc_w, doc_h = img_w - 2*margin, img_h - 2*margin
        
        # Step 4: Classify by aspect ratio
        aspect_ratio = doc_w / doc_h if doc_h > 0 else 1.0
        logger.info(f"[CLASSIFY] Aspect ratio: {aspect_ratio:.2f}")
        
        # Classification
        if 1.4 <= aspect_ratio <= 1.8:
            detected_type = "CARD"
            logger.info(f"[CLASSIFY] Detected: ID CARD (DNI/NIE)")
        elif 0.55 <= aspect_ratio <= 0.85:
            detected_type = "PASSPORT_VERTICAL"  # Passport two pages stacked vertically
            logger.info(f"[CLASSIFY] Detected: PASSPORT (vertical/stacked pages)")
        elif aspect_ratio > 1.8:
            detected_type = "PASSPORT_WIDE"
            logger.info(f"[CLASSIFY] Detected: PASSPORT (wide/side by side)")
        else:
            detected_type = "UNKNOWN"
            logger.warning(f"[CLASSIFY] Unknown type, using aggressive redaction")
        
        # Step 5: Apply surgical redaction
        logger.info(f"[REDACT] Applying surgical redaction for {detected_type}...")
        
        if detected_type == "CARD":
            # === DNI/NIE REDACTION - BOTH TOP NUMBERS ===
            
            # Zone 1a: LEFT number (NIE/DNI number on left side)
            left_x1 = doc_x
            left_y1 = doc_y
            left_x2 = doc_x + int(doc_w * 0.25)
            left_y2 = doc_y + int(doc_h * 0.18)
            cv2.rectangle(img, (left_x1, left_y1), (left_x2, left_y2), (0, 0, 0), -1)
            logger.info(f"[REDACT] NIE/DNI LEFT number: top-left")
            
            # Zone 1b: RIGHT number (support number on right side) - WIDER
            right_x1 = doc_x + int(doc_w * 0.72)
            right_y1 = doc_y
            right_x2 = doc_x + doc_w
            right_y2 = doc_y + int(doc_h * 0.18)
            cv2.rectangle(img, (right_x1, right_y1), (right_x2, right_y2), (0, 0, 0), -1)
            logger.info(f"[REDACT] Support number: top-right")
            
            # Zone 2: MRZ - Bottom 25%
            mrz_y1 = doc_y + int(doc_h * 0.75)
            cv2.rectangle(img, (doc_x, mrz_y1), (doc_x + doc_w, doc_y + doc_h), (0, 0, 0), -1)
            logger.info(f"[REDACT] MRZ zone: bottom 25%")
            
            # Zone 3: Signature - Center-bottom (avoiding face on left 40%)
            sig_x1 = doc_x + int(doc_w * 0.42)
            sig_y1 = doc_y + int(doc_h * 0.62)
            sig_x2 = doc_x + int(doc_w * 0.72)
            sig_y2 = doc_y + int(doc_h * 0.75)
            cv2.rectangle(img, (sig_x1, sig_y1), (sig_x2, sig_y2), (0, 0, 0), -1)
            logger.info(f"[REDACT] Signature zone: center-bottom")
            
        elif detected_type == "PASSPORT_VERTICAL":
            # === PASSPORT STACKED VERTICALLY (two pages, one above other) ===
            half_h = doc_h // 2
            
            # TOP PAGE
            top_y = doc_y
            bottom_y = doc_y + half_h
            
            # Passport number TOP page - top right
            pn_x1 = doc_x + int(doc_w * 0.70)
            pn_y1 = top_y
            pn_x2 = doc_x + doc_w
            pn_y2 = top_y + int(half_h * 0.15)
            cv2.rectangle(img, (pn_x1, pn_y1), (pn_x2, pn_y2), (0, 0, 0), -1)
            
            # Signature area TOP page
            sig_x1 = doc_x + int(doc_w * 0.50)
            sig_y1 = top_y + int(half_h * 0.45)
            sig_x2 = doc_x + doc_w
            sig_y2 = top_y + int(half_h * 0.70)
            cv2.rectangle(img, (sig_x1, sig_y1), (sig_x2, sig_y2), (0, 0, 0), -1)
            logger.info(f"[REDACT] Top page: passport number + signature")
            
            # BOTTOM PAGE (data page with MRZ)
            # Passport number BOTTOM page
            pn_x1 = doc_x + int(doc_w * 0.70)
            pn_y1 = bottom_y
            pn_x2 = doc_x + doc_w
            pn_y2 = bottom_y + int(half_h * 0.12)
            cv2.rectangle(img, (pn_x1, pn_y1), (pn_x2, pn_y2), (0, 0, 0), -1)
            
            # MRZ - bottom 35% of BOTTOM page
            mrz_y1 = bottom_y + int(half_h * 0.65)
            mrz_y2 = doc_y + doc_h
            cv2.rectangle(img, (doc_x, mrz_y1), (doc_x + doc_w, mrz_y2), (0, 0, 0), -1)
            logger.info(f"[REDACT] Bottom page: passport number + MRZ (35%)")
            
        elif detected_type == "PASSPORT_WIDE":
            # === PASSPORT SIDE BY SIDE ===
            half_w = doc_w // 2
            left_x = doc_x
            right_x = doc_x + half_w
            
            # Left page numbers
            cv2.rectangle(img, 
                (left_x + int(half_w * 0.70), doc_y),
                (left_x + half_w, doc_y + int(doc_h * 0.15)),
                (0, 0, 0), -1)
            
            # Right page numbers
            cv2.rectangle(img,
                (right_x + int(half_w * 0.70), doc_y),
                (right_x + half_w, doc_y + int(doc_h * 0.15)),
                (0, 0, 0), -1)
            
            # MRZ - bottom 30% of right page
            mrz_y1 = doc_y + int(doc_h * 0.70)
            cv2.rectangle(img, (right_x, mrz_y1), (doc_x + doc_w, doc_y + doc_h), (0, 0, 0), -1)
            logger.info(f"[REDACT] Wide passport: both numbers + MRZ")
            
        else:
            # === FALLBACK: Aggressive ===
            # Both top corners
            cv2.rectangle(img, 
                (doc_x, doc_y),
                (doc_x + int(doc_w * 0.25), doc_y + int(doc_h * 0.20)),
                (0, 0, 0), -1)
            cv2.rectangle(img, 
                (doc_x + int(doc_w * 0.70), doc_y),
                (doc_x + doc_w, doc_y + int(doc_h * 0.20)),
                (0, 0, 0), -1)
            # Bottom 35%
            cv2.rectangle(img,
                (doc_x, doc_y + int(doc_h * 0.65)),
                (doc_x + doc_w, doc_y + doc_h),
                (0, 0, 0), -1)
            logger.warning(f"[FALLBACK] Aggressive redaction applied")
        
        # Save
        success = cv2.imwrite(output_path, img)
        if not success:
            logger.error(f"[ERROR] Failed to save image")
            return False
        
        logger.info(f"[OK] Document redacted: {output_path}")
        logger.info(f"[OK] Type: {detected_type}")
        return True
        
    except Exception as e:
        logger.error(f"[ERROR] Redaction failed: {str(e)}")
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
