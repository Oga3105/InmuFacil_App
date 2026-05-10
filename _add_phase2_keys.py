import json
import glob
import os

keys_to_add = {
    "property_listing": {
        "how_works": "Cómo funciona",
        "favorites": "Favoritos",
        "filters": "Filtros",
        "publish_property": "Publicar inmueble",
        "filters_and_search": "Filtros y Búsqueda",
        "lifestyle_sorting_notice": "Mostrando resultados priorizados por tu Estilo de Vida",
        "spain": "España",
        "search": "Buscar",
        "all": "Todo",
        "all_properties": "Todas las propiedades",
        "properties_in": "Propiedades en {}",
        "results_count": "{} resultados",
        "list_view": "Lista",
        "grid_view": "Cuadrícula",
        "map_view": "Mapa",
        "no_properties_found": "No se encontraron propiedades",
        "try_changing_filters": "Intenta cambiar los filtros de búsqueda",
        "sort_by": {
            "newest": "Más recientes",
            "relevance": "Relevancia (Estilo de Vida)",
            "price_low_high": "Precio: menor a mayor",
            "price_high_low": "Precio: mayor a menor",
            "label": "Ordenar por"
        },
        "bedrooms_unit": "Hab.",
        "bathrooms_unit": "Baños",
        "sqm_unit": "m²",
        "verified_seller": "VENDEDOR VERIFICADO",
        "share": "Compartir",
        "contact_owner": "Contactar Propietario",
        "protected_location": "UBICACIÓN PROTEGIDA",
        "cancel": "Cancelar",
        "account_required_title": "Cuenta requerida",
        "account_required_msg": "Para contactar particulares debes estar registrado.",
        "login_btn": "Iniciar sesión",
        "verification_required_title": "Verificación requerida",
        "verification_required_msg": "Solo los usuarios verificados pueden contactar particulares.",
        "verify_identity_btn": "Verificar identidad",
        "make_offer_first_title": "Haz una oferta primero",
        "make_offer_first_msg": "Para poder chatear con el propietario, primero debes hacer una oferta.",
        "understood": "Entendido",
        "make_offer_btn": "Hacer Oferta",
        "location_hint": "Ciudad, barrio o zona...",
        "search_button": "Buscar",
        "price_range": "Rango de Precio",
        "bedrooms": "Habitaciones",
        "bedrooms_short": "Hab.",
        "property_type": "Tipo de inmueble",
        "extras": "Extras y comodidades",
        "extra_labels": {
            "pool": "Piscina",
            "garage": "Garaje",
            "terrace": "Terraza",
            "garden": "Jardín",
            "lift": "Ascensor",
            "ac": "Aire Acondicionado",
            "heating": "Calefacción",
            "storage": "Trastero",
            "wardrobes": "Armarios Empotrados",
            "exterior": "Exterior",
            "accessible": "Acceso movilidad reducida"
        },
        "clear_filters": "Limpiar Filtros",
        "edit_lifestyle": "Editar mi estilo de vida",
        "verified_badge": "SOLO VERIFICADOS",
        "promo": {
            "title": "¿Vendes tu casa?",
            "subtitle": "Publica gratis y llega a compradores.",
            "learn_more": "Saber más"
        }
    },
    "map": {
        "zone_label": "Zona seleccionada",
        "draw_instruction": "Dibuja el área de búsqueda",
        "finish_btn": "Finalizar",
        "clear_map_tooltip": "Limpiar mapa",
        "cancel_draw_tooltip": "Cancelar dibujo",
        "draw_zone_tooltip": "Dibujar zona",
        "zoom_in_tooltip": "Acercar",
        "zoom_out_tooltip": "Alejar",
        "my_location_tooltip": "Mi ubicación",
        "location_error": "No se pudo obtener la ubicación",
        "view_details": "Ver detalles",
        "view_detail_btn": "Ver detalle"
    },
    "lifestyle": {
        "lifestyle_filter_title": "Filtro por Estilo de Vida",
        "lifestyle_filter_description": "Nuestra IA ordenará las propiedades según tu afinidad."
    },
    "property_status": {
        "published": "PUBLICADO",
        "draft": "BORRADOR",
        "unpublished": "NO PUBLICADO"
    }
}

additional_home_keys = {
    "bedrooms_filter_label": "Habitaciones"
}

files = glob.glob('frontend/assets/translations/*.json')

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Add new root keys
    for root_key, sub_dict in keys_to_add.items():
        if root_key not in data:
            data[root_key] = {}
        for k, v in sub_dict.items():
            if k not in data[root_key]:
                data[root_key][k] = v
            elif isinstance(v, dict) and isinstance(data[root_key][k], dict):
                for sub_k, sub_v in v.items():
                    if sub_k not in data[root_key][k]:
                        data[root_key][k][sub_k] = sub_v
    
    # Add to home root
    if "home" not in data:
        data["home"] = {}
    for k, v in additional_home_keys.items():
        if k not in data["home"]:
            data["home"][k] = v

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Phase 2 keys added successfully.")
