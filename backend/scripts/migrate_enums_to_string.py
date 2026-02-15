from sqlalchemy import create_engine, text

# Using direct URL
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

def migrate_enums():
    print(f"Connecting to DB to migrate enums...")
    engine = create_engine(DATABASE_URL)
    
    # Mapping based on enums.py order
    mapping = {
        0: "piso",
        1: "atico",
        2: "duplex",
        3: "chalet",
        4: "casa_rustica",
        5: "casa_singular",
        6: "local",
        7: "oficina",
        8: "nave",
        9: "edificio",
        10: "garaje",
        11: "terreno",
        12: "finca_rustica",
        13: "apartment",
        14: "house",
        15: "land",
        16: "office",
        17: "villa"
    }
    
    try:
        with engine.connect() as conn:
            # 1. Update property_type in properties table
            for idx, val in mapping.items():
                # We check if it is exactly the integer (or string representation of integer)
                # PostgreSQL Enum columns can be tricky if they are strictly typed.
                # If they were created without native PG enum, they are likely VARCHAR or INTEGER.
                
                sql = text("UPDATE properties SET property_type = :val WHERE property_type = :idx")
                result = conn.execute(sql, {"val": val, "idx": str(idx)})
                if result.rowcount > 0:
                    print(f"✅ Migrated {result.rowcount} rows: {idx} -> {val}")
            
            # Special case for 'casa' which was in seed data but maybe not in main enum exactly as 'casa'
            # (seed_data.py had PropertyType.CASA but enums.py has CASA_RUSTICA/SINGULAR)
            # Actually seed_data.py Step 19366 had PropertyType.CASA which might have failed if PropertyType.CASA doesn't exist?
            # Wait, Step 19402: seed_data.py had PropertyType.PISO for Loft.
            
            conn.commit()
            print("Enum migration committed.")
    except Exception as e:
        print(f"❌ Error migrating enums: {repr(e)}")

if __name__ == "__main__":
    migrate_enums()
