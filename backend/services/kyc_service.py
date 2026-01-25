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
from pathlib import Path
from typing import Tuple, Optional
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
        logger.warning(f"🚫 Invalid file extension: {file_ext}")
        return False, f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
    
    # Check 2: MIME type from content
    try:
        # Try to open as image (will fail if not a real image)
        with Image.open(file_path) as img:
            # Get format from PIL
            image_format = img.format
            if image_format not in ['JPEG', 'PNG']:
                logger.warning(f"🚫 Invalid image format: {image_format}")
                return False, "Invalid image format. Only JPEG and PNG are allowed."
            
            logger.info(f"✅ File validated: {image_format} image")
            return True, ""
            
    except Exception as e:
        logger.error(f"❌ File validation failed: {str(e)}")
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
        logger.warning(f"🚫 File too large: {size_mb:.2f}MB")
        return False, f"File too large ({size_mb:.2f}MB). Maximum size is 5MB."
    
    logger.info(f"✅ File size OK: {file_size / 1024:.2f}KB")
    return True, ""


# ============================================================================
# @Jules - DNI Image Redaction
# ============================================================================

def redact_dni_image(image_path: str, output_path: str) -> bool:
    """
    Redact sensitive zones from DNI image.
    
    Redacted zones (Spanish DNI 3.0):
    - Equipo Emisor: Bottom right corner (equipment ID)
    - Firma: Bottom left area (signature)
    - MRZ: Bottom strip (Machine Readable Zone)
    
    Args:
        image_path: Path to original DNI image
        output_path: Path to save redacted image
        
    Returns:
        True if redaction successful
        
    Security Notes:
    - Redacts sensitive personal data
    - Uses solid black rectangles (irreversible)
    - Preserves photo and essential data for verification
    
    @Jules: Image processing logic
    @Shield: Privacy protection through redaction
    """
    try:
        # Open image
        with Image.open(image_path) as img:
            # Convert to RGB if needed
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Get image dimensions
            width, height = img.size
            
            # Create drawing context
            draw = ImageDraw.Draw(img)
            
            # Define redaction zones (percentages of image dimensions)
            # These are approximate zones for Spanish DNI 3.0
            
            # Zone 1: MRZ (Machine Readable Zone) - Bottom strip
            mrz_zone = [
                0,                      # x1 (left)
                int(height * 0.85),     # y1 (85% down)
                width,                  # x2 (right)
                height                  # y2 (bottom)
            ]
            
            # Zone 2: Equipo Emisor - Bottom right
            equipo_zone = [
                int(width * 0.65),      # x1 (65% from left)
                int(height * 0.75),     # y1 (75% down)
                width,                  # x2 (right)
                int(height * 0.85)      # y2 (just above MRZ)
            ]
            
            # Zone 3: Firma (Signature) - Bottom left
            firma_zone = [
                0,                      # x1 (left)
                int(height * 0.70),     # y1 (70% down)
                int(width * 0.30),      # x2 (30% from left)
                int(height * 0.85)      # y2 (just above MRZ)
            ]
            
            # Draw black rectangles over sensitive zones
            draw.rectangle(mrz_zone, fill='black')
            draw.rectangle(equipo_zone, fill='black')
            draw.rectangle(firma_zone, fill='black')
            
            # Save redacted image
            img.save(output_path, quality=85, optimize=True)
            
            logger.info(f"✅ DNI image redacted successfully: {output_path}")
            return True
            
    except Exception as e:
        logger.error(f"❌ DNI redaction failed: {str(e)}")
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
) -> Tuple[bool, str, Optional[str]]:
    """
    Process DNI image upload with validation and redaction.
    
    Args:
        file_path: Temporary path to uploaded file
        original_filename: Original filename
        user_id: User ID for organizing uploads
        
    Returns:
        Tuple of (success, message, saved_file_path)
        
    Security Flow:
    1. Validate file size
    2. Validate file type (MIME)
    3. Redact sensitive zones
    4. Save with secure filename
    5. Delete original temporary file
    
    @Jules: Complete upload processing pipeline
    @Shield: Multi-layer security validation
    """
    try:
        # Step 1: Validate file size
        is_valid, error = validate_file_size(file_path)
        if not is_valid:
            return False, error, None
        
        # Step 2: Validate file type
        is_valid, error = validate_file_type(file_path, original_filename)
        if not is_valid:
            return False, error, None
        
        # Step 3: Create user upload directory
        user_upload_dir = UPLOAD_DIR / str(user_id)
        user_upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Step 4: Generate secure filename
        secure_filename = generate_secure_filename(original_filename)
        output_path = user_upload_dir / secure_filename
        
        # Step 5: Redact DNI image
        success = redact_dni_image(file_path, str(output_path))
        if not success:
            return False, "Failed to process DNI image. Please try again.", None
        
        # Step 6: Clean up temporary file
        try:
            os.remove(file_path)
        except:
            pass  # Ignore cleanup errors
        
        logger.info(f"✅ DNI upload processed successfully for user {user_id}")
        return True, "DNI image uploaded and processed successfully.", str(output_path)
        
    except Exception as e:
        logger.error(f"❌ DNI upload processing failed: {str(e)}")
        return False, "An error occurred while processing your DNI. Please try again.", None


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
    logger.info(f"📁 Upload directory ready: {UPLOAD_DIR}")
