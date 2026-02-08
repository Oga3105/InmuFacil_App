"""
Image Service (@Jules)
Handles secure image processing, resizing, and storage.
"""

import os
import shutil
import uuid
from PIL import Image
from fastapi import UploadFile, HTTPException
from pathlib import Path

# Constants
UPLOAD_DIR = "uploads/properties"
MAX_IMAGE_SIZE = (1920, 1080)  # Full HD
THUMBNAIL_SIZE = (400, 300)
ALLOWED_FORMATS = {"JPEG", "JPG", "PNG", "WEBP"}

# Ensure upload directory exists
os.makedirs(UPLOAD_DIR, exist_ok=True)


def validate_image(file: UploadFile) -> None:
    """
    Validates file type using Pillow (more reliable than MIME type headers).
    """
    try:
        img = Image.open(file.file)
        img.verify()  # Check for corruption
        
        # Reset file pointer after verify()
        file.file.seek(0)
        
        if img.format.upper() not in ALLOWED_FORMATS:
             raise HTTPException(status_code=400, detail=f"Invalid image format. Allowed: {ALLOWED_FORMATS}")
             
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file or corrupted data.")


def process_and_save_image(file: UploadFile, property_id: int) -> str:
    """
    Resizes, compresses, and saves the image.
    Returns the relative path to the saved file.
    """
    # 1. Create property specific folder
    prop_dir = Path(UPLOAD_DIR) / str(property_id)
    prop_dir.mkdir(parents=True, exist_ok=True)
    
    # 2. Generate unique filename (protect against path traversal)
    extension = file.filename.split(".")[-1].lower()
    if extension not in ["jpg", "jpeg", "png", "webp"]:
        extension = "jpg" # Default to JPG if unknown but valid image
        
    filename = f"{uuid.uuid4()}.{extension}"
    file_path = prop_dir / filename
    
    # 3. Process with Pillow
    try:
        with Image.open(file.file) as img:
            # Convert RGBA to RGB if needed (for JPEG saving)
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")
                
            # Resize fit
            img.thumbnail(MAX_IMAGE_SIZE, Image.Resampling.LANCZOS)
            
            # Save optimized
            img.save(file_path, optimize=True, quality=85)
            
            return str(file_path).replace("\\", "/") # Normalize path for DB
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")
