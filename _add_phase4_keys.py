import json
import os

def load_json(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_json(filepath, data):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

keys_to_add = {
    "property_wizard": {
        "title_ai_hint": "La descripción comercial se genera con IA en el siguiente paso.",
        "market_ref": "Referencia de mercado: ",
        "market_ref_detail": "({} EUR/m², {})",
        "cee_hint": "Indica la calificación energética de la propiedad.",
        "cee_pending": "En trámite",
        "cee_pending_selected": "Certificado en trámite seleccionado",
        "cee_rating_selected": "Calificación {} seleccionada"
    }
}

translations_dir = "frontend/assets/translations"

def update_language(lang_code):
    filepath = os.path.join(translations_dir, f"{lang_code}.json")
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    data = load_json(filepath)
    
    for section, keys in keys_to_add.items():
        if section not in data:
            data[section] = {}
        for k, v in keys.items():
            if k not in data[section]:
                data[section][k] = v
                print(f"[{lang_code}] Added: {section}.{k} = {v}")

    save_json(filepath, data)

languages = [
    "es-ES", "ca-ES", "en-US", "fr-FR", "de-DE",
    "pt-PT", "it-IT", "nl-NL", "ru-RU", "va-ES"
]

for lang in languages:
    update_language(lang)

print("Phase 4 keys injected successfully.")
