"""
@Watcher - Secure Document Service
@Jules - OCR Integration

Handles upload, encryption, and OCR Verification of legal documents.
"""

import base64
import os
from datetime import datetime
from fastapi import UploadFile
from backend.src.utils.crypto import encrypt_data, decrypt_data
from backend.src.services.kyc_service import get_ocr_reader
import cv2
import numpy as np


class ComplianceError(Exception):
    pass


def process_document(file: UploadFile, property_id: int, doc_type: str) -> dict:
    """
    1. Reads file.
    2. Performs OCR (if Nota Simple) to find Catastral Ref.
    3. Encrypts content.
    4. Returns encrypted blob — caller stores it in PostgreSQL (no filesystem write).
    """
    try:
        content = file.file.read()
    except Exception:
        raise ComplianceError("Failed to read file")
    finally:
        file.file.seek(0)

    ocr_data = {}
    if file.content_type.startswith("image/"):
        if doc_type == "nota_simple":
            ocr_data = _extract_nota_simple_data(content)

    content_b64 = base64.b64encode(content).decode("utf-8")
    encrypted_blob = encrypt_data(content_b64)

    return {
        "encrypted_content": encrypted_blob,
        "metadata": ocr_data,
    }


def _extract_nota_simple_data(image_bytes: bytes) -> dict:
    """
    Uses EasyOCR to find 'Referencia Catastral'.
    Pattern: 20 alphanumeric chars.
    """
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    reader = get_ocr_reader()
    results = reader.readtext(img, detail=0)

    extracted = {"raw_text": " ".join(results)}

    import re
    ref_matches = re.findall(r'\b[A-Za-z0-9]{20}\b', extracted["raw_text"])
    if ref_matches:
        extracted["catastral_ref"] = ref_matches[0]

    return extracted


def get_decrypted_document(encrypted_content: str) -> bytes:
    """
    Accepts an AES-256 encrypted+base64 string (from DB),
    decrypts it and returns raw bytes.
    """
    try:
        decrypted_b64 = decrypt_data(encrypted_content)
        return base64.b64decode(decrypted_b64)
    except Exception:
        raise ComplianceError("Decryption failed")


def get_decrypted_document_from_path(file_path: str) -> bytes:
    """
    Legacy fallback: reads encrypted file from disk, decrypts, returns bytes.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError("Document not found on disk")

    with open(file_path, "r") as f:
        encrypted_blob = f.read()

    return get_decrypted_document(encrypted_blob)
