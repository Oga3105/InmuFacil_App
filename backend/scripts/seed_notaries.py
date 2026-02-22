
import sys
import os
from sqlalchemy.orm import Session

# Add project root to sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from backend.src.config.database import SessionLocal, engine
from backend.src.models.notaries import Notary

def seed_notaries():
    db = SessionLocal()
    try:
        # Check if already seeded
        if db.query(Notary).first():
            print("ℹ️ Notaries already seeded.")
            return

        notaries = [
            Notary(name="Notaría García", address_line="Calle Mayor 1", city="Madrid", email="garcia@notaria.com", phone="910000001"),
            Notary(name="Notaría López", address_line="Av. Diagonal 200", city="Barcelona", email="lopez@notaria.com", phone="930000002"),
            Notary(name="Notaría Digital", address_line="Online", city="Nube", email="digital@notaria.com", phone="900000003")
        ]
        
        db.add_all(notaries)
        db.commit()
        print("✅ Seeded 3 Notaries.")
    
    except Exception as e:
        print(f"❌ Error seeding notaries: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_notaries()
