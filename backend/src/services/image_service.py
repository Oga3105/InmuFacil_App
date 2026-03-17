"""
Image Service (@Jules)
Handles secure image processing and DB storage.
Includes InmuFacil watermark applied at 30% opacity (bottom-right corner).
Images are stored as BYTEA in PostgreSQL — no filesystem writes.
"""

import io
from PIL import Image, ImageDraw, ImageFont
from fastapi import UploadFile, HTTPException

# Constants
MAX_IMAGE_SIZE = (1920, 1080)  # Full HD
ALLOWED_FORMATS = {"JPEG", "JPG", "PNG", "WEBP"}


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


def process_image_to_bytes(file: UploadFile) -> tuple[bytes, str]:
    """
    Resizes, watermarks, and compresses the image.
    Returns (image_bytes, content_type) — no filesystem writes.
    """
    try:
        with Image.open(file.file) as img:
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")

            img.thumbnail(MAX_IMAGE_SIZE, Image.Resampling.LANCZOS)
            img = _apply_watermark(img)

            buffer = io.BytesIO()
            img.save(buffer, format="JPEG", optimize=True, quality=85)
            return buffer.getvalue(), "image/jpeg"

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")
