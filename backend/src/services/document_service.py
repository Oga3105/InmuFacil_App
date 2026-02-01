"""
@Watcher - Secure Document Service
@Jules - OCR Integration

Handles upload, encryption, and OCR Verification of legal documents.
"""

import os
from datetime import datetime
from fastapi import UploadFile
from backend.src.utils.crypto import encrypt_data, decrypt_data
# Reuse OCR from KYC service? Or import easyocr directly?
# Ideally we reuse the Reader instance to save memory.
# We will import the lazy loader from kyc_service if possible, or replicate the pattern.
from backend.src.services.kyc_service import get_ocr_reader
import shutil
import cv2
import numpy as np

UPLOAD_DIR = "uploads/compliance"
os.makedirs(UPLOAD_DIR, exist_ok=True)

class ComplianceError(Exception):
    pass

def process_document(file: UploadFile, property_id: int, doc_type: str) -> dict:
    """
    1. Reads file.
    2. Performs OCR (if Nota Simple) to find Catastral Ref.
    3. Encrypts content.
    4. Saves to disk.
    """
    # 1. Read Content
    try:
        content = file.file.read()
    except Exception:
        raise ComplianceError("Failed to read file")
    finally:
        file.file.seek(0)

    ocr_data = {}
    
    # 2. OCR (Only if Image/PDF) - For MVP we assume Images for OCR
    # If PDF, we would need pdf2image.
    if file.content_type.startswith("image/"):
        if doc_type == "nota_simple":
             ocr_data = _extract_nota_simple_data(content)
    
    # 3. Encrypt
    # content is bytes. crypto.encrypt_data expects str? 
    # backend.crypto.encrypt_data uses .encode(), so it expects str.
    # We need a function for RAW bytes encryption.
    # If crypto.py only handles strings, we can base64 encode the bytes to strat first.
    import base64
    content_b64 = base64.b64encode(content).decode('utf-8')
    encrypted_blob = encrypt_data(content_b64) # Returns encrypted string
    
    # 4. Save
    filename = f"{property_id}_{doc_type}_{datetime.now().timestamp()}.enc"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    with open(file_path, "w") as f:
        f.write(encrypted_blob)
        
    return {
        "file_path": file_path,
        "metadata": ocr_data
    }

def _extract_nota_simple_data(image_bytes: bytes) -> dict:
    """
    Uses EasyOCR to find 'Referencia Catastral'.
    Pattern: 20 alphanumeric chars.
    """
    # Bytes to CV2
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    reader = get_ocr_reader()
    results = reader.readtext(img, detail=0) # Just text list
    
    extracted = {"raw_text": " ".join(results)}
    
    # Searching for Catastral Ref pattern (20 chars)
    # Simple heuristic: Look for long alphanumeric strings
    import re
    # 20 chars: digits and uppercase. DNI pattern was specific, Ref Catastral is 20 digits/letters.
    # e.g. 9872023 VH5797S 0001 WX
    # Regex: [A-Z0-9]{20}
    
    ref_matches = re.findall(r'\b[A-Za-z0-9]{20}\b', extracted["raw_text"])
    if ref_matches:
        extracted["catastral_ref"] = ref_matches[0]
        
    return extracted

def get_decrypted_document(file_path: str) -> bytes:
    """
    Reads encrypted file, decrypts, debase64, returns bytes.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError("Document not found on disk")
        
    with open(file_path, "r") as f:
        encrypted_blob = f.read()
        
    try:
        decrypted_b64 = decrypt_data(encrypted_blob)
        import base64
    except Exception:
        raise ComplianceError("Decryption failed")

class DocumentService:
    """
    Service wrapper for document operations.
    """
    @staticmethod
    async def save_protected_document(file: UploadFile, filename_prefix: str) -> str:
        """
        Generic secure text/file saver.
        Encrypts and saves with a specific prefix/name logic.
        """
        try:
            content = await file.read() # Async read
        except Exception:
            raise ComplianceError("Failed to read file")
        finally:
            await file.seek(0)

        # Encrypt
        import base64
        # Handle if content is str or bytes
        if isinstance(content, str):
            content_b = content.encode()
        else:
            content_b = content
            
        content_b64 = base64.b64encode(content_b).decode('utf-8')
        encrypted_blob = encrypt_data(content_b64)
        
        # Save
        filename = f"{filename_prefix}_{datetime.now().timestamp()}.enc"
        # Sanitize filename
        filename = "".join([c for c in filename if c.isalnum() or c in "._-"])
        
        file_path = os.path.join(UPLOAD_DIR, filename)
        
        with open(file_path, "w") as f:
            f.write(encrypted_blob)
            
        return file_path

