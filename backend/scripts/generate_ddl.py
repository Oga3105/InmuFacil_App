from sqlalchemy.schema import CreateTable
from backend.models import Property, PropertyFeatures, PropertyLegal, PropertyFinancial, PropertyEnvironment, PropertyMedia
from backend.database import engine

# Force compilation to use Postgres dialect
from sqlalchemy.dialects import postgresql

def print_ddl(model):
    print(CreateTable(model.__table__).compile(dialect=postgresql.dialect()))

try:
    print_ddl(PropertyMedia)
    print(";")
except Exception as e:
    print(f"Error: {e}")
