"""
Diagnostic script: manual API smoke-test for offers and chat endpoints.
Usage:
    TEST_USER_OWNER=propietario@test.com TEST_USER_BUYER=comprador@test.com \
    TEST_PASSWORD=password123 python backend/scripts/api_check.py
"""
import os
import urllib.request
import urllib.parse
import json

BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:8000/api/v1")
TEST_PASSWORD = os.environ.get("TEST_PASSWORD", "password123")
TEST_USER_OWNER = os.environ.get("TEST_USER_OWNER", "propietario@test.com")
TEST_USER_BUYER = os.environ.get("TEST_USER_BUYER", "comprador@test.com")


def post_json(url, data):
    req = urllib.request.Request(
        url, data=urllib.parse.urlencode(data).encode("utf-8")
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"Error: {e.code} - {e.read().decode('utf-8')}")
        return None


def get_json(url, token):
    req = urllib.request.Request(
        url, headers={"Authorization": f"Bearer {token}"}
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(f"Error: {e.code} - {e.read().decode('utf-8')}")
        return None


# 1. Login as owner — check received offers
print(f"Logging in as {TEST_USER_OWNER}")
login_data = post_json(
    f"{BASE_URL}/auth/login",
    {"username": TEST_USER_OWNER, "password": TEST_PASSWORD},
)
if login_data:
    token = login_data["access_token"]
    print("Login successful.")

    print("\nFetching received offers:")
    offers = get_json(f"{BASE_URL}/offers/me/received", token)
    if offers is not None:
        print(f"Total offers received: {len(offers)}")
        for o in offers:
            print(f"- Offer ID {o['id']} (Status: {o['status']})")
            print(f"  Last Msg: {o.get('last_message')} | Unread: {o.get('unread_count')}")
            print(f"  Confirmed Visit: {o.get('confirmed_visit_date')}")
            print(f"  Requested Visit: {o.get('requested_visit_date')}")
            print(f"  Visit Status:    {o.get('visit_status')}")

            chat = get_json(f"{BASE_URL}/offers/{o['id']}/chat", token)
            if chat is not None:
                print("  --- Chat History ---")
                for c in chat:
                    print(
                        f"    [{c['timestamp']}] {c['sender_id']}: "
                        f"{c['message_type']} - {c['message']} "
                        f"(Meta: {c.get('metadata')})"
                    )

# 2. Login as buyer — check sent offers
print(f"\nTrying as {TEST_USER_BUYER}...")
login_data = post_json(
    f"{BASE_URL}/auth/login",
    {"username": TEST_USER_BUYER, "password": TEST_PASSWORD},
)
if login_data:
    token = login_data["access_token"]
    print("Login successful.")
    print("\nFetching sent offers:")
    offers = get_json(f"{BASE_URL}/offers/me/sent", token)
    if offers is not None:
        print(f"Total offers sent: {len(offers)}")
        for o in offers:
            print(f"- Offer ID {o['id']} (Status: {o['status']})")
            print(f"  Last Msg: {o['last_message']} | Unread: {o['unread_count']}")
            print(f"  Confirmed Visit: {o.get('confirmed_visit_date')}")
            print(f"  Requested Visit: {o.get('requested_visit_date')}")
            print(f"  Visit Status:    {o.get('visit_status')}")
