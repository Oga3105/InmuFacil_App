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

def test_everything():
    db = SessionLocal()
    try:
        properties = db.query(Property).all()
        print(f"Total properties: {len(properties)}")
        
        for p in properties:
            print(f"\n🏠 Property: {p.title}")
            try:
                # Use from_orm or model_validate
                PropertyResponse.model_validate(p)
                print("✅ Success!")
            except Exception as e:
                print(f"❌ Failed: {repr(e)}")
                if hasattr(e, 'errors'):
                    errors = e.errors()
                    for err in errors:
                        print(f"   - Location: {err['loc']}, Msg: {err['msg']}, Input: {err.get('input')}")

    finally:
        db.close()

if __name__ == "__main__":
    test_everything()
