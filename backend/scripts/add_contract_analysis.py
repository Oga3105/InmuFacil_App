from sqlalchemy import create_engine, MetaData, Table, Column, Integer, String, Float, DateTime, ForeignKey, Boolean, text
from sqlalchemy.types import JSON
from sqlalchemy.engine import reflection
import os
from dotenv import load_dotenv

def upgrade():
    load_dotenv()
    # Use direct URL or env, avoiding package import issues
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./inmufacil.db")
    print(f"Migrating DB: {DATABASE_URL}")
    
    engine = create_engine(DATABASE_URL)
    
    # Debug: Check existing tables
    inspector = reflection.Inspector.from_engine(engine)
    print("Existing tables:", inspector.get_table_names())
    
    metadata = MetaData()
    
    # 1. Add custom_contract_path to offers table
    inspector = reflection.Inspector.from_engine(engine)
    columns = [c['name'] for c in inspector.get_columns('offers')]
    
    if 'custom_contract_path' not in columns:
        print("Adding custom_contract_path to offers...")
        with engine.connect() as conn:
            conn.execute(text("ALTER TABLE offers ADD COLUMN custom_contract_path VARCHAR"))
    else:
        print("Column custom_contract_path already exists.")

    # 2. Create contract_analysis table
    if not inspector.has_table("contract_analysis"):
        # Reflect 'offers' so FK works
        Table('offers', metadata, autoload_with=engine)
        
        print("Creating contract_analysis table...")
        contract_analysis = Table(
            'contract_analysis', metadata,
            Column('id', Integer, primary_key=True, index=True),
            Column('offer_id', Integer, ForeignKey('offers.id'), nullable=False),
            Column('analysis_json', JSON, nullable=True),
            Column('role', String, nullable=False), # BUYER or SELLER
            Column('cost', Float, default=0.0),
            Column('consent_timestamp', DateTime(timezone=True), nullable=False), # Liability Critical
            Column('disclaimer_version', String, nullable=False), # e.g. "v1.0"
            Column('created_at', DateTime(timezone=True), server_default=text('(CURRENT_TIMESTAMP)'))
        )
        metadata.create_all(engine)
        print("Table contract_analysis created.")
    else:
        print("Table contract_analysis already exists.")

if __name__ == "__main__":
    upgrade()
