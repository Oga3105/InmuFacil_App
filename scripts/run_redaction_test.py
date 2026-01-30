"""
Simple redaction test runner
"""
import sys
sys.path.insert(0, '.')

from tests.test_redaction import test_redaction_complete

print("\n🔐 Executing Privacy Redaction Verification Suite...\n")
result = test_redaction_complete()

if result:
    print("\n✅ REDACTION TEST: PASSED\n")
    sys.exit(0)
else:
    print("\n❌ REDACTION TEST: FAILED\n")
    sys.exit(1)
