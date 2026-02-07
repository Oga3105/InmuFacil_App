import requests
import json

url = "http://localhost:8000/api/v1/leads/"
headers = {"Content-Type": "application/json"}
data = {"email": "test_lead_capture@example.com"}

try:
    response = requests.post(url, headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.json()}")
    
    if response.status_code in [200, 201]:
        print("✅ TEST PASSED: Lead captured successfully.")
    else:
        print("❌ TEST FAILED: Unexpected status code.")

    # Test Idempotency (Duplicate)
    print("\nTesting Idempotency (Duplicate Email)...")
    response_duplicate = requests.post(url, headers=headers, json=data)
    print(f"Status Code: {response_duplicate.status_code}")
    # Should be 200 or 201, and same body
    if response_duplicate.status_code in [200, 201]:
         print("✅ TEST PASSED: Duplicate handled silently (Idempotency).")
    else:
         print("❌ TEST FAILED: Duplicate caused error.")

except Exception as e:
    print(f"❌ TEST FAILED: Connection error - {e}")
