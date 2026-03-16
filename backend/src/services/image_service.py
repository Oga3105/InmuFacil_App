"""
Image Service (@Jules)
Handles secure image processing, resizing, and storage.
Includes InmuFacil watermark applied at 30% opacity (bottom-right corner).
"""

import os
import shutil
import uuid
from PIL import Image, ImageDraw, ImageFont
from fastapi import UploadFile, HTTPException
from pathlib import Path

# Constants
UPLOAD_DIR = "uploads/properties"
MAX_IMAGE_SIZE = (1920, 1080)  # Full HD
THUMBNAIL_SIZE = (400, 300)
ALLOWED_FORMATS = {"JPEG", "JPG", "PNG", "WEBP"}

# Ensure upload directory exists
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _apply_watermark(img: Image.Image) -> Image.Image:
    """
    Add 'InmuFacil' text watermark centered horizontally at the bottom.
    Font scales to occupy ~40% of image width. White text + dark shadow for
    visibility on any background.
    """
    img_rgba = img.convert("RGBA")
    w, h = img_rgba.size

    text = "InmuFacil"

    # Find the font size that makes text_width ≈ 40% of image width.
    # Binary-search between 10 and 400 px.
    target_w = int(w * 0.40)
    lo, hi = 10, 400
    font = ImageFont.load_default()
    chosen_size = lo
    _probe_img = Image.new("RGBA", (1, 1))
    _probe_draw = ImageDraw.Draw(_probe_img)
    for _ in range(20):          # ~20 iterations is enough
        mid = (lo + hi) // 2
        try:
            f = ImageFont.load_default(size=mid)
        except TypeError:
            f = ImageFont.load_default()
        bb = _probe_draw.textbbox((0, 0), text, font=f)
        tw = bb[2] - bb[0]
        if tw < target_w:
            lo = mid
            font = f
            chosen_size = mid
        else:
            hi = mid
        if hi - lo <= 1:
            break

    # Measure final dimensions
    bb = _probe_draw.textbbox((0, 0), text, font=font)
    text_w = bb[2] - bb[0]
    text_h = bb[3] - bb[1]

    # Position: centered horizontally, bottom area with small margin
    margin_bottom = max(16, h // 20)
    x = (w - text_w) // 2
    y = h - text_h - margin_bottom

    txt_layer = Image.new("RGBA", img_rgba.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(txt_layer)

    # Dark shadow (2 px offset) for contrast on light backgrounds
    shadow_offset = max(2, chosen_size // 20)
    draw.text((x + shadow_offset, y + shadow_offset), text, font=font,
              fill=(0, 0, 0, 160))
    # White text at 75% opacity: 0.75 * 255 ≈ 191
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 191))

    watermarked = Image.alpha_composite(img_rgba, txt_layer)
    return watermarked.convert("RGB")


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

            # Apply InmuFacil watermark (30% opacity, bottom-right)
            img = _apply_watermark(img)

            # Save optimized
            img.save(file_path, optimize=True, quality=85)
            
            return str(file_path).replace("\\", "/") # Normalize path for DB
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")
