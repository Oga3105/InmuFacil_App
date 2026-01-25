"""
@Jules - Redaction Test Suite
@Shield - Pixel-level Verification
@Watcher - Security Report Generation

Automated privacy redaction verification with fail-safe pixel validation.
Ensures 100% opacity in redacted zones.

Token Consumption Tracking: ~500 tokens for redaction tests
"""

import os
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw
from backend.services.kyc_service import redact_dni_image, redact_dni
import logging

logger = logging.getLogger("inmufacil.test.redaction")


# ============================================================================
# @Jules - Test Image Generation
# ============================================================================

def generate_test_dni_image(output_path: str) -> bool:
    """
    Generate a simulated DNI image for testing redaction.
    
    Args:
        output_path: Path to save test image
        
    Returns:
        True if generation successful
        
    Test Image Layout (800x500px):
    - Top: Name area with text
    - Middle: Photo placeholder
    - Bottom Left (70-85%): Firma (signature)
    - Bottom Right (65-85%): Equipo Emisor
    - Bottom Strip (85-100%): MRZ
    
    @Jules: Test data generation
    """
    try:
        # Create white background image
        width, height = 800, 500
        img = Image.new('RGB', (width, height), color='white')
        draw = ImageDraw.Draw(img)
        
        # Draw colored zones to simulate DNI content
        # These will be redacted and should become 100% black
        # NO BORDERS to avoid compression artifacts
        
        # Zone 1: Firma (Signature) - Bottom left - RED for visibility
        firma_zone = [
            0,                      # x1 (left)
            int(height * 0.70),     # y1 (70% down)
            int(width * 0.30),      # x2 (30% from left)
            int(height * 0.85)      # y2 (just above MRZ)
        ]
        draw.rectangle(firma_zone, fill='red')  # No outline
        
        # Zone 2: Equipo Emisor - Bottom right - BLUE for visibility
        equipo_zone = [
            int(width * 0.65),      # x1 (65% from left)
            int(height * 0.75),     # y1 (75% down)
            width,                  # x2 (right)
            int(height * 0.85)      # y2 (just above MRZ)
        ]
        draw.rectangle(equipo_zone, fill='blue')  # No outline
        
        # Zone 3: MRZ (Machine Readable Zone) - Bottom strip - GREEN for visibility
        mrz_zone = [
            0,                      # x1 (left)
            int(height * 0.85),     # y1 (85% down)
            width,                  # x2 (right)
            height                  # y2 (bottom)
        ]
        draw.rectangle(mrz_zone, fill='green')  # No outline
        
        # Add non-redacted content (should remain visible)
        draw.text((10, 10), "NOMBRE: TEST USUARIO", fill='black')
        draw.text((10, 40), "DNI: 12345678A", fill='black')
        
        # Save image as PNG (lossless) to avoid JPEG compression artifacts
        img.save(output_path, 'PNG')
        logger.info(f"✅ Test DNI image generated: {output_path}")
        return True
        
    except Exception as e:
        logger.error(f"❌ Test image generation failed: {str(e)}")
        return False


# ============================================================================
# @Shield - Pixel-level Verification
# ============================================================================

def verify_redaction_pixels(image_path: str) -> tuple[bool, dict]:
    """
    Verify that redacted zones are 100% black (#000000).
    
    Args:
        image_path: Path to redacted image
        
    Returns:
        Tuple of (all_black, report_dict)
        
    Security Verification:
    - Checks every pixel in redacted zones
    - Fails if ANY pixel is not black
    - Provides detailed report of non-black pixels
    
    @Shield: Fail-safe pixel validation
    """
    try:
        img = Image.open(image_path)
        width, height = img.size
        pixels = img.load()
        
        # Define redaction zones (same as in kyc_service.py)
        zones = {
            'MRZ': {
                'x1': 0,
                'y1': int(height * 0.85),
                'x2': width,
                'y2': height
            },
            'Equipo_Emisor': {
                'x1': int(width * 0.65),
                'y1': int(height * 0.75),
                'x2': width,
                'y2': int(height * 0.85)
            },
            'Firma': {
                'x1': 0,
                'y1': int(height * 0.70),
                'x2': int(width * 0.30),
                'y2': int(height * 0.85)
            }
        }
        
        report = {
            'total_pixels_checked': 0,
            'non_black_pixels': 0,
            'zones_verified': {},
            'failed_zones': []
        }
        
        # Check each zone
        for zone_name, coords in zones.items():
            zone_pixels = 0
            non_black = 0
            non_black_samples = []
            
            for y in range(coords['y1'], coords['y2']):
                for x in range(coords['x1'], coords['x2']):
                    zone_pixels += 1
                    pixel = pixels[x, y]
                    
                    # Check if pixel is black (0, 0, 0)
                    if pixel != (0, 0, 0):
                        non_black += 1
                        if len(non_black_samples) < 5:  # Keep first 5 samples
                            non_black_samples.append({
                                'position': (x, y),
                                'color': pixel
                            })
            
            report['zones_verified'][zone_name] = {
                'pixels_checked': zone_pixels,
                'non_black_pixels': non_black,
                'is_100_percent_black': non_black == 0,
                'samples': non_black_samples
            }
            
            report['total_pixels_checked'] += zone_pixels
            report['non_black_pixels'] += non_black
            
            if non_black > 0:
                report['failed_zones'].append(zone_name)
        
        all_black = report['non_black_pixels'] == 0
        
        if all_black:
            logger.info(f"✅ Redaction verification PASSED: All {report['total_pixels_checked']} pixels are black")
        else:
            logger.error(f"❌ Redaction verification FAILED: {report['non_black_pixels']} non-black pixels found")
        
        return all_black, report
        
    except Exception as e:
        logger.error(f"❌ Pixel verification failed: {str(e)}")
        return False, {'error': str(e)}


# ============================================================================
# @Watcher - Security Report Generation
# ============================================================================

def generate_security_report(test_passed: bool, report: dict) -> str:
    """
    Generate security report for redaction test.
    
    Args:
        test_passed: Whether test passed
        report: Detailed verification report
        
    Returns:
        Formatted security report string
        
    @Watcher: Security compliance reporting
    """
    lines = []
    lines.append("=" * 70)
    lines.append("🔐 PRIVACY REDACTION VERIFICATION REPORT")
    lines.append("=" * 70)
    
    if test_passed:
        lines.append("✅ STATUS: PASSED")
        lines.append(f"✅ Total pixels verified: {report['total_pixels_checked']:,}")
        lines.append("✅ All redacted zones are 100% opaque (black)")
        lines.append("")
        lines.append("ZONE VERIFICATION:")
        for zone_name, zone_data in report['zones_verified'].items():
            lines.append(f"  ✅ {zone_name}: {zone_data['pixels_checked']:,} pixels - 100% BLACK")
    else:
        lines.append("❌ STATUS: FAILED")
        lines.append(f"❌ Non-black pixels found: {report['non_black_pixels']}")
        lines.append(f"❌ Failed zones: {', '.join(report['failed_zones'])}")
        lines.append("")
        lines.append("ZONE VERIFICATION:")
        for zone_name, zone_data in report['zones_verified'].items():
            status = "✅" if zone_data['is_100_percent_black'] else "❌"
            lines.append(f"  {status} {zone_name}: {zone_data['non_black_pixels']} non-black pixels")
            
            if zone_data['samples']:
                lines.append(f"     Sample non-black pixels:")
                for sample in zone_data['samples']:
                    lines.append(f"       Position {sample['position']}: RGB{sample['color']}")
    
    lines.append("=" * 70)
    lines.append("SECURITY STANDARD: 100% Opacity Required")
    lines.append("COMPLIANCE: " + ("✅ PASSED" if test_passed else "❌ FAILED"))
    lines.append("=" * 70)
    
    return "\n".join(lines)


# ============================================================================
# @Jules + @Shield + @Watcher - Complete Test Suite
# ============================================================================

def test_redaction_complete():
    """
    Complete redaction test with automatic cleanup.
    
    Test Flow:
    1. @Jules: Generate test DNI image
    2. @Jules: Apply redaction
    3. @Shield: Verify 100% black pixels
    4. @Watcher: Generate security report
    5. Cleanup: Delete test images
    
    Returns:
        True if test passed
    """
    temp_dir = tempfile.mkdtemp()
    test_image_path = None
    redacted_image_path = None
    
    try:
        logger.info("🧪 Starting redaction verification test...")
        
        # Step 1: Generate test image (PNG for lossless quality)
        test_image_path = os.path.join(temp_dir, "test_dni.png")
        success = generate_test_dni_image(test_image_path)
        
        if not success:
            logger.error("❌ Test image generation failed")
            return False
        
        # Step 2: Apply redaction (PNG output for lossless quality)
        redacted_image_path = os.path.join(temp_dir, "test_dni_redacted.png")
        success = redact_dni_image(test_image_path, redacted_image_path)
        
        if not success:
            logger.error("❌ Redaction failed")
            return False
        
        # Step 3: Verify pixels
        all_black, report = verify_redaction_pixels(redacted_image_path)
        
        # Step 4: Generate report
        security_report = generate_security_report(all_black, report)
        print("\n" + security_report + "\n")
        
        return all_black
        
    except Exception as e:
        logger.error(f"❌ Test failed with exception: {str(e)}")
        return False
        
    finally:
        # Step 5: Cleanup - Delete test images
        try:
            if test_image_path and os.path.exists(test_image_path):
                os.remove(test_image_path)
                logger.info(f"🗑️  Deleted test image: {test_image_path}")
            
            if redacted_image_path and os.path.exists(redacted_image_path):
                os.remove(redacted_image_path)
                logger.info(f"🗑️  Deleted redacted image: {redacted_image_path}")
            
            if os.path.exists(temp_dir):
                os.rmdir(temp_dir)
                logger.info(f"🗑️  Deleted temp directory: {temp_dir}")
                
        except Exception as e:
            logger.warning(f"⚠️  Cleanup warning: {str(e)}")


if __name__ == "__main__":
    # Run test when executed directly
    print("\n🔐 Executing Privacy Redaction Verification Suite...\n")
    test_passed = test_redaction_complete()
    
    if test_passed:
        print("\n✅ REDACTION TEST: PASSED")
        print("✅ System meets 100% opacity standard\n")
        exit(0)
    else:
        print("\n❌ REDACTION TEST: FAILED")
        print("❌ System does NOT meet 100% opacity standard\n")
        exit(1)
