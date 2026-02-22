import os
import sys

# Setup paths
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(current_dir)
parent_dir = os.path.dirname(backend_dir)
sys.path.append(parent_dir)
sys.path.append(backend_dir)

from sqlalchemy.orm import Session
from backend.src.config.database import SessionLocal
from backend.src.models import Property
from backend.src.schemas.base import PropertyResponse

def debug_serialization():
    db = SessionLocal()
    try:
        properties = db.query(Property).all()
        print(f"Total properties: {len(properties)}")
        
        for p in properties:
            print(f"\n🏠 Property: {p.title} (ID: {p.id})")
            print(f"   property_type: {p.property_type} (type: {type(p.property_type)})")
            if p.features:
                print(f"   features.conservation_state: {p.features.conservation_state} (type: {type(p.features.conservation_state)})")
                print(f"   features.floor: {p.features.floor}")
            
            try:
                # Simulate FastAPI's validation from ORM
                print("   --- Attempting model_validate ---")
                valid_data = PropertyResponse.model_validate(p)
                print("   ✅ Success!")
            except Exception as e:
                print(f"   ❌ Failed: {repr(e)}")
                if hasattr(e, 'errors'):
                    for err in e.errors():
                        print(f"     Location: {err['loc']}")
                        print(f"     Message: {err['msg']}")
                        print(f"     Input: {err.get('input')}\n")

    finally:
        db.close()

if __name__ == "__main__":
    debug_serialization()
