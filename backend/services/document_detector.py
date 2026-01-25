"""
@Jules - Intelligent Document Detection Helper

Uses OpenCV to detect and locate the document within an image.
Implements contour detection to find the largest rectangle (the document).

Token Consumption Tracking: ~200 tokens for detection helper
"""

import cv2
import numpy as np
import logging

logger = logging.getLogger("inmufacil.kyc")


def detect_document_bounds(image_path: str) -> tuple:
    """
    Detect document boundaries within an image using OpenCV contour detection.
    
    Args:
        image_path: Path to the image file
        
    Returns:
        Tuple of (x, y, width, height) representing document bounds,
        or None if detection fails
        
    Detection Strategy:
    1. Convert to grayscale
    2. Apply Gaussian blur to reduce noise
    3. Edge detection with Canny
    4. Find contours
    5. Identify largest rectangular contour (the document)
    6. Fallback: Use center 80% if no clear rectangle found
    
    @Jules: Computer vision for intelligent document localization
    """
    try:
        # Read image
        img = cv2.imread(image_path)
        if img is None:
            logger.error(f"[ERROR] Could not read image: {image_path}")
            return None
        
        height, width = img.shape[:2]
        
        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Edge detection
        edges = cv2.Canny(blurred, 50, 150)
        
        # Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Find largest contour (likely the document)
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            x, y, w, h = cv2.boundingRect(largest_contour)
            
            # Validate that the detected rectangle is reasonable
            # (at least 40% of image area, aspect ratio between 1.3 and 1.8 for ID cards)
            area_ratio = (w * h) / (width * height)
            aspect_ratio = w / h if h > 0 else 0
            
            if area_ratio > 0.4 and 1.2 < aspect_ratio < 2.0:
                logger.info(f"[OK] Document detected: {w}x{h} at ({x}, {y})")
                logger.info(f"[OK] Area ratio: {area_ratio:.2%}, Aspect ratio: {aspect_ratio:.2f}")
                return (x, y, w, h)
        
        # Fallback: Use center 80% of image
        logger.warning("[WARNING] No clear document detected, using center 80% fallback")
        margin_x = int(width * 0.10)
        margin_y = int(height * 0.10)
        fallback_bounds = (
            margin_x,
            margin_y,
            width - 2 * margin_x,
            height - 2 * margin_y
        )
        logger.info(f"[OK] Fallback bounds: {fallback_bounds}")
        return fallback_bounds
        
    except Exception as e:
        logger.error(f"[ERROR] Document detection failed: {str(e)}")
        return None
