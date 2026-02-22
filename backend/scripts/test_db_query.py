import os
import sys

# Setup path to include backend/ so we can import 'src'
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(current_dir)
parent_dir = os.path.dirname(backend_dir)

sys.path.append(parent_dir)
sys.path.append(backend_dir)

try:
    from backend.src.models.enums import PropertyType
    from backend.src.schemas.base import PropertyResponse
except ImportError as e:
    print(f"❌ Import Error: {e}")
    sys.exit(1)

def diag():
    print("📋 Inspecting PropertyType members:")
    for member in PropertyType:
        print(f"   - {member.name}: {member.value} (Type: {type(member.value)})")
    
    print("\n� Inspecting PropertyFeaturesSchema expectation:")
    from backend.src.schemas.base import PropertyFeaturesSchema
    # Check what fields are expected
    print(f"   Fields: {PropertyFeaturesSchema.model_fields.keys()}")
    
    # Try a dummy validation
    print("\n📋 Testing dummy PropertyType validation (value='piso'):")
    from pydantic import TypeAdapter
    try:
        ta = TypeAdapter(PropertyType)
        val = ta.validate_python("piso")
        print(f"   ✅ Validation 'piso' success: {val}")
    except Exception as e:
        print(f"   ❌ Validation 'piso' failed: {repr(e)}")

    try:
        val = ta.validate_python(0)
        print(f"   ✅ Validation 0 success: {val}")
    except Exception as e:
        print(f"   ❌ Validation 0 failed: {repr(e)}")

if __name__ == "__main__":
    diag()
