"""
@Jules - TDD for Hito 9: Compliance & OCR
"""
import pytest
from unittest.mock import MagicMock, patch
from backend.src.services.document_service import process_document, get_decrypted_document
from backend.src.models import DocumentType
from fastapi import UploadFile
import os
import io

# Mock Data
FAKE_CATASTRAL = "9872023VH5797S0001WX" # 20 chars
FAKE_IMAGE_CONTENT = b"Fake Image Bytes"

@pytest.fixture
def mock_upload_file():
    file = MagicMock(spec=UploadFile)
    file.filename = "nota_simple.jpg"
    file.content_type = "image/jpeg"
    file.file = io.BytesIO(FAKE_IMAGE_CONTENT)
    return file

@patch("backend.src.services.document_service.get_ocr_reader")
@patch("backend.src.services.document_service.encrypt_data")
def test_process_document_flow(mock_encrypt, mock_get_reader, mock_upload_file, tmp_path):
    # Setup Mocks
    mock_encrypt.return_value = "ENCRYPTED_BLOB"
    
    mock_reader = MagicMock()
    # Simulate OCR finding the Ref Catastral in the text
    mock_reader.readtext.return_value = ["Texto irrelevante", f"Ref: {FAKE_CATASTRAL}", "Fin"]
    mock_get_reader.return_value = mock_reader
    
    # Redirect upload dir to tmp_path for test safety
    with patch("backend.src.services.document_service.UPLOAD_DIR", str(tmp_path)):
        # Execute
        result = process_document(mock_upload_file, property_id=1, doc_type="nota_simple")
        
        # Verify Encryption called
        mock_encrypt.assert_called_once()
        
        # Verify File Saved
        assert os.path.exists(result["file_path"])
        with open(result["file_path"], "r") as f:
            content = f.read()
            assert content == "ENCRYPTED_BLOB"
            
        # Verify OCR Logic
        assert "metadata" in result
        assert result["metadata"]["catastral_ref"] == FAKE_CATASTRAL

@patch("backend.src.services.document_service.decrypt_data")
def test_decrypt_flow(mock_decrypt, tmp_path):
    # Setup
    fake_confidential = "CONFIDENTIAL_DATA"
    import base64
    fake_encrypted = "ENCRYPTED_STRING"
    
    # Create fake encrypted file
    file_path = tmp_path / "test_doc.enc"
    file_path.write_text(fake_encrypted)
    
    # Mock Decrypt to return base64 of original data
    mock_decrypt.return_value = base64.b64encode(fake_confidential.encode()).decode()
    
    # Execute
    result_bytes = get_decrypted_document(str(file_path))
    
    # Verify
    assert result_bytes == fake_confidential.encode()
    mock_decrypt.assert_called_with(fake_encrypted)
