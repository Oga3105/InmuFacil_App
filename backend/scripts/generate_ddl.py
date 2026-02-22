from sqlalchemy.schema import CreateTable
from backend.models import VisitWindow, VisitAppointment
from backend.database import engine

# Force compilation to use Postgres dialect
from sqlalchemy.dialects import postgresql

def print_ddl(model):
    print(CreateTable(model.__table__).compile(dialect=postgresql.dialect()))

try:
    print_ddl(VisitWindow)
    print(";")
    print_ddl(VisitAppointment)
    print(";")
except Exception as e:
    print(f"Error: {e}")
