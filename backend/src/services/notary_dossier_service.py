
import os
import zipfile
import hashlib
import json
from datetime import datetime
from sqlalchemy.orm import Session
from backend.src.models.offers import PropertyOffer
# from backend.src.services.kyc_service import KYCService
from backend.src.config.database import SessionLocal # Or inject

# Mock Vault Service for "Unmasking"
# In Hito 14, we simulate retrieving the original DNI images.
# In a real impl, this would call the Vault with the Master Key.

class NotaryDossierService:
    def __init__(self, db: Session):
        self.db = db

    def generate_dossier_zip(self, offer_id: int) -> str:
        """
        Generates a ZIP file containing all necessary documents for the Notary.
        Includes MANIFEST.txt with SHA256 hashes.
        Returns path to the ZIP file.
        """
        offer = self.db.query(PropertyOffer).get(offer_id)
        if not offer or not offer.notary_id:
            raise ValueError("Offer not found or no notary assigned")

        base_dir = f"temp_dossiers/{offer_id}"
        os.makedirs(base_dir, exist_ok=True)
        
        files_to_zip = []

        # 1. Recuperar Contrato Firmado (Simulado)
        contract_path = self._get_signed_contract(offer, base_dir)
        files_to_zip.append(contract_path)

        # 2. Recuperar Nota Simple (Simulado)
        nota_simple = self._get_nota_simple(offer, base_dir)
        files_to_zip.append(nota_simple)

        # 3. UNMASKING: Recuperar DNI del Vendedor (Simulado)
        dni_seller = self._unmask_dni(offer.property.owner_id, "vendedor", base_dir)
        files_to_zip.append(dni_seller)

        # 4. UNMASKING: Recuperar DNI del Comprador (Simulado)
        dni_buyer = self._unmask_dni(offer.buyer_id, "comprador", base_dir)
        files_to_zip.append(dni_buyer)

        # 5. Generar MANIFEST.txt
        manifest_path = self._generate_manifest(files_to_zip, base_dir)
        files_to_zip.append(manifest_path)

        # 6. Create ZIP
        zip_filename = f"dossier_notaria_oferta_{offer_id}.zip"
        zip_path = os.path.join("temp_dossiers", zip_filename)
        
        with zipfile.ZipFile(zip_path, 'w') as zipf:
            for file in files_to_zip:
                zipf.write(file, os.path.basename(file))
        
        # Cleanup (Optional: remove temp dir, keep zip)
        # For dev, we keep files to inspect
        
        return zip_path

    def _get_signed_contract(self, offer, base_dir):
        path = os.path.join(base_dir, "contrato_arras_firmado.pdf")
        with open(path, "w") as f:
            f.write(f"Contenido del Contrato de Arras Firmado para Oferta {offer.id}")
        return path

    def _get_nota_simple(self, offer, base_dir):
        path = os.path.join(base_dir, "nota_simple.pdf")
        with open(path, "w") as f:
            f.write(f"Nota Simple de la Propiedad {offer.property_id}")
        return path

    def _unmask_dni(self, user_id, role, base_dir):
        # SIMULATION: In real life, we would decrypt the image from Vault.
        # Here we create a dummy file marked as "UNMASKED"
        path = os.path.join(base_dir, f"dni_{role}_{user_id}_unmasked.jpg")
        with open(path, "w") as f:
            f.write(f"IMAGEN DNI ORIGINAL DESENCRIPTADA ({role})")
        return path

    def _generate_manifest(self, file_paths, base_dir):
        manifest_lines = [
            f"MANIFESTO DE SEGURIDAD - DOSSIER NOTARIAL",
            f"Fecha: {datetime.now().isoformat()}",
            "----------------------------------------",
            "Archivos incluidos y firmas SHA256:",
            ""
        ]
        
        for file_path in file_paths:
            filename = os.path.basename(file_path)
            sha256 = self._calculate_sha256(file_path)
            manifest_lines.append(f"{filename}: {sha256}")
            
        manifest_lines.append("")
        manifest_lines.append("CONFIDENCIAL: Este paquete contiene datos personales desprotegidos bajo secreto notarial.")
        
        manifest_path = os.path.join(base_dir, "MANIFEST.txt")
        with open(manifest_path, "w") as f:
            f.write("\n".join(manifest_lines))
            
        return manifest_path

    def _calculate_sha256(self, file_path):
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            # Read and update hash string value in blocks of 4K
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
