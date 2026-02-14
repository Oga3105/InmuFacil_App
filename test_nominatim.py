import requests
import json

# Test Nominatim API for Sevilla
url = "https://nominatim.openstreetmap.org/search?q=sevilla&format=json&limit=5&countrycodes=es&addressdetails=1"
headers = {"User-Agent": "com.inmufacil.app/1.0"}

response = requests.get(url, headers=headers)
data = response.json()

print("=" * 80)
print("NOMINATIM RESULTS FOR 'SEVILLA'")
print("=" * 80)

for i, result in enumerate(data):
    print(f"\n--- RESULT {i+1} ---")
    print(f"Display Name: {result.get('display_name', 'N/A')}")
    print(f"Type: {result.get('type', 'N/A')}")
    print(f"Class: {result.get('class', 'N/A')}")
    print(f"Address Type: {result.get('addresstype', 'N/A')}")
    print(f"OSM Type: {result.get('osm_type', 'N/A')}")
    print(f"Place Rank: {result.get('place_rank', 'N/A')}")
    print(f"Importance: {result.get('importance', 'N/A')}")
    
    if 'address' in result:
        addr = result['address']
        print(f"Address Details:")
        for key, value in addr.items():
            print(f"  - {key}: {value}")

print("\n" + "=" * 80)
print("ANALYSIS:")
print("=" * 80)

# Check which result is the city
for i, result in enumerate(data):
    addresstype = result.get('addresstype', '')
    if addresstype in ['city', 'town', 'municipality', 'village']:
        print(f"✅ RESULT {i+1} is a {addresstype.upper()} - THIS SHOULD BE SELECTED")
    else:
        print(f"❌ RESULT {i+1} is a {addresstype.upper()} - Should be ignored")
