from sqlalchemy import create_engine, text

# Using direct URL
DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/inmufacil_db"

def migrate_all_enums():
    print(f"Connecting to DB for comprehensive enum migration...")
    engine = create_engine(DATABASE_URL)
    
    # Tables and their enum columns
    # mapping is based on enums.py definition order (0-indexed)
    
    config = {
        "properties": {
            "property_type": {
                0: "piso", 1: "atico", 2: "duplex", 3: "chalet", 4: "casa_rustica",
                5: "casa_singular", 6: "local", 7: "oficina", 8: "nave", 9: "edificio",
                10: "garaje", 11: "terreno", 12: "finca_rustica"
            },
            "status": {
                0: "published", 1: "reserved", 2: "sold"
            },
            "operation_type": {
                0: "venta", 1: "alquiler", 2: "btr", 3: "inversion"
            }
        },
        "property_features": {
            "conservation_state": {
                0: "a_estrenar", 1: "buen_estado", 2: "a_reformar"
            },
            "orientation": {
                0: "norte", 1: "sur", 2: "este", 3: "oeste", 
                4: "noreste", 5: "noroeste", 6: "sureste", 7: "suroeste"
            },
            "heating_type": {
                0: "gas_natural", 1: "electrica", 2: "central", 3: "aerotermia", 4: "otro"
            }
        },
        "property_legal": {
            "energy_certification": {
                0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G", 7: "exento", 8: "en_tramite"
            },
            "ite_status": {
                0: "pasada", 1: "pendiente", 2: "desfavorable", 3: "no_obligado"
            },
            "nota_simple_status": {
                0: "pending", 1: "verified", 2: "rejected"
            }
        }
    }
    
    try:
        with engine.connect() as conn:
            for table, columns in config.items():
                for column, mapping in columns.items():
                    print(f"Migrating {table}.{column}...")
                    for idx, val in mapping.items():
                        sql = text(f"UPDATE {table} SET {column} = :val WHERE {column} = :idx")
                        result = conn.execute(sql, {"val": val, "idx": str(idx)})
                        if result.rowcount > 0:
                            print(f"  ✅ {table}.{column}: {idx} -> {val} ({result.rowcount} rows)")
            
            conn.commit()
            print("\n🎉 Comprehensive migration committed.")
    except Exception as e:
        print(f"❌ Error during migration: {repr(e)}")

if __name__ == "__main__":
    migrate_all_enums()
