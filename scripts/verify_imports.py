import sys
import os

# Ensure project root is in path
sys.path.append(os.getcwd())

print("Attempting to import backend.main...")
try:
    # We treat backend as a package. 
    # Must be run from project root (parent of backend)
    from backend.main import app
    print("SUCCESS: backend.main imported successfully.")
except Exception as e:
    print(f"FAILURE: {e}")
    import traceback
    traceback.print_exc()
