import json
import glob
import os

keys_to_add = {
    "ai_consent": {
        "error_generic": "Ocurrió un error. Inténtalo de nuevo.",
        "title": "Consentimiento de IA (RGPD)",
        "action_label": "Acción",
        "data_sent_label": "Datos compartidos",
        "ai_provider_label": "Proveedor de IA",
        "purpose_label": "Propósito",
        "legal_warning": "Tus datos se procesarán de forma segura a través de {provider}. Al aceptar, consientes el tratamiento de tus datos para esta finalidad específica según nuestra Política de Privacidad.",
        "cancel_btn": "Cancelar",
        "accept_btn": "Aceptar"
    },
    "ai_rate_limit": {
        "title": "Límite de IA alcanzado",
        "message": "Has alcanzado el límite diario para {category}. Vuelve a intentarlo mañana o actualiza tu plan."
    },
    "quota_alert": {
        "warning": "Atención: Te acercas al límite de uso de IA.",
        "critical": "Alerta: Uso crítico de IA. Pronto se agotará tu cuota.",
        "exceeded": "Límite excedido: No puedes realizar más consultas de IA hoy."
    },
    "comfort": {
        "error": "Error al cargar el índice de confort.",
        "title": "Índice de Confort",
        "request_error": "No se pudo enviar la solicitud.",
        "no_consent_info": "El propietario no ha consentido el cálculo de confort para esta vivienda. Solicítalo para poder ver el detalle.",
        "request_btn": "Solicitar Índice",
        "dim_noise": "Ruido",
        "dim_light": "Luminosidad",
        "dim_air": "Calidad del Aire",
        "dim_connectivity": "Conectividad",
        "dim_thermal": "Confort Térmico",
        "overall_score": "Puntuación global: {}/100",
        "low_data_banner": "Pocos datos en esta zona. La estimación podría variar."
    },
    "doc_verification": {
        "section_title": "Documentación Verificada",
        "cee_title": "Certificado Energético",
        "nota_simple_title": "Nota Simple",
        "cedula_title": "Cédula de Habitabilidad"
    },
    "market_price": {
        "low_density": "Pocos datos para estimar el precio en esta zona.",
        "unavailable": "Estimación de precio no disponible.",
        "title": "Precio de Mercado Estimado",
        "no_extrapolation": "Datos orientativos. No extrapolar sin tasación oficial.",
        "confidence_high": "CONFIANZA ALTA",
        "confidence_medium": "CONFIANZA MEDIA",
        "confidence_low": "CONFIANZA BAJA"
    },
    "discovery": {
        "twins": {
            "loading": "Buscando barrios similares...",
            "section_title": "Barrios Gemelos",
            "section_subtitle": "Zonas con estilo de vida y precios similares"
        }
    },
    "nota_simple": {
        "upload_unavailable": "La subida de documentos no está disponible en este entorno.",
        "charges_dialog_title": "Detalle de Cargas Registrales",
        "charges_dialog_close": "Cerrar",
        "upload_button": "Subir Nota Simple",
        "summary_title": "Resumen de Nota Simple",
        "invalid_document_title": "Documento Inválido",
        "titular_label": "Titular principal:",
        "surface_registered": "Superficie registral:",
        "surface_announced": "Superficie anunciada:",
        "surface_alert": "Discrepancia del {pct}% entre anuncio y registro.",
        "charges_title": "Cargas Registrales",
        "no_charges": "Libre de cargas registrales relevantes.",
        "charges_detail_button": "Ver detalle de cargas",
        "charge_risk_alto": "ALTO RIESGO",
        "charge_risk_estandar": "ESTÁNDAR",
        "charge_risk_informativo": "INFORMATIVO"
    },
    "urban_growth": {
        "error": "Error al estimar crecimiento urbano.",
        "low_data_default": "Información insuficiente para la previsión en esta zona.",
        "title": "Previsión de Crecimiento",
        "projected_label": "Revalorización estimada a 5 años:",
        "no_projection": "Sin previsión",
        "milestones_title": "Hitos urbanísticos próximos:",
        "signals_title": "Señales de crecimiento:",
        "zone_mature": "ZONA CONSOLIDADA",
        "zone_emerging": "ZONA EMERGENTE",
        "zone_declining": "ZONA EN DECLIVE",
        "zone_unknown": "DESCONOCIDA"
    }
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

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Phase 3 keys added successfully.")
