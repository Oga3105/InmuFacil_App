"""
@Jules - Document Normalization Engine

Detects document corners and applies perspective transformation to normalize
documents to standard ID-1 card size (1011x638 pixels).

Token Consumption Tracking: ~500 tokens for normalization module
"""

import cv2
import numpy as np
import logging
from typing import Optional, Tuple

logger = logging.getLogger("inmufacil.normalizer")

# ID-1 card standard dimensions at 300 DPI
# Physical: 85.6mm × 53.98mm
# Digital: 1011 × 638 pixels
STANDARD_WIDTH = 1011
STANDARD_HEIGHT = 638


def order_points(pts: np.ndarray) -> np.ndarray:
    """
    Order corner points in consistent order for perspective transform.
    
    Args:
        pts: Array of 4 points
        
    Returns:
        Ordered points: [top-left, top-right, bottom-right, bottom-left]
        
    @Jules: Geometric ordering for consistent transforms
    """
    # Initialize ordered points
    rect = np.zeros((4, 2), dtype=np.float32)
    
    # Top-left point has smallest sum (x+y)
    # Bottom-right has largest sum
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]
    
    # Top-right has smallest difference (y-x)
    # Bottom-left has largest difference
    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]
    rect[3] = pts[np.argmax(diff)]
    
    return rect


def find_document_corners(img: np.ndarray) -> Optional[np.ndarray]:
    """
    Find 4 corners of document using contour detection.
    
    Args:
        img: Input image (BGR)
        
    Returns:
        4 corner points ordered [TL, TR, BR, BL] or None if not found
        
    Detection Strategy:
    1. Adaptive thresholding (handles white backgrounds)
    2. Morphological operations (clean noise)
    3. Find contours
    4. Filter for quadrilateral shapes
    5. Select largest quadrilateral as document
    
    @Jules: Robust corner detection with multiple fallbacks
    """
    try:
        height, width = img.shape[:2]
        
        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Apply adaptive thresholding
        thresh = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV,
            11, 2
        )
        
        # Morphological operations to clean up
        kernel = np.ones((5, 5), np.uint8)
        morph = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
        morph = cv2.morphologyEx(morph, cv2.MORPH_OPEN, kernel)
        
        # Find contours
        contours, _ = cv2.findContours(morph, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            logger.warning("[NORMALIZER] No contours found")
            return None
        
        # Sort by area, largest first
        contours = sorted(contours, key=cv2.contourArea, reverse=True)
        
        # Try top 5 contours
        for contour in contours[:5]:
            # Approximate contour to polygon
            peri = cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, 0.02 * peri, True)
            
            # Check if it's a quadrilateral
            if len(approx) == 4:
                # Validate area (should be at least 30% of image)
                area = cv2.contourArea(approx)
                area_ratio = area / (width * height)
                
                if area_ratio > 0.3:
                    # Found valid quadrilateral
                    corners = approx.reshape(4, 2).astype(np.float32)
                    ordered = order_points(corners)
                    
                    logger.info(f"[OK] Document corners detected (area: {area_ratio:.2%})")
                    return ordered
        
        logger.warning("[NORMALIZER] No valid quadrilateral found")
        return None
        
    except Exception as e:
        logger.error(f"[ERROR] Corner detection failed: {str(e)}")
        return None


def normalize_document(img: np.ndarray, corners: np.ndarray) -> np.ndarray:
    """
    Apply perspective transform to warp document to ID-1 standard size.
    
    Args:
        img: Input image
        corners: 4 corner points [TL, TR, BR, BL]
        
    Returns:
        Normalized image (1011x638 pixels)
        
    @Jules: Perspective transformation to standard card size
    """
    # Destination points (standard ID-1 card)
    dst = np.array([
        [0, 0],                              # Top-left
        [STANDARD_WIDTH - 1, 0],             # Top-right
        [STANDARD_WIDTH - 1, STANDARD_HEIGHT - 1],  # Bottom-right
        [0, STANDARD_HEIGHT - 1]             # Bottom-left
    ], dtype=np.float32)
    
    # Calculate perspective transform matrix
    M = cv2.getPerspectiveTransform(corners, dst)
    
    # Apply warp
    warped = cv2.warpPerspective(img, M, (STANDARD_WIDTH, STANDARD_HEIGHT))
    
    logger.info(f"[OK] Document normalized to {STANDARD_WIDTH}x{STANDARD_HEIGHT}")
    return warped


def aggressive_center_crop(img: np.ndarray) -> np.ndarray:
    """
    Fallback: Extract center 90% and resize to standard size.
    
    Args:
        img: Input image
        
    Returns:
        Cropped and resized image (1011x638 pixels)
        
    Security Note:
    Used when corner detection fails. Applies aggressive crop to minimize
    background and ensure document fills frame for better redaction coverage.
    
    @Shield: Fallback ensures no data leaks
    """
    h, w = img.shape[:2]
    
    # Extract center 90%
    margin_x = int(w * 0.05)
    margin_y = int(h * 0.05)
    
    cropped = img[margin_y:h-margin_y, margin_x:w-margin_x]
    
    # Resize to standard size
    normalized = cv2.resize(cropped, (STANDARD_WIDTH, STANDARD_HEIGHT))
    
    logger.warning(f"[FALLBACK] Using aggressive center-crop (90% of image)")
    return normalized
