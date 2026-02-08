/// Temporary translation helper
/// Simple extension to replace .tr() calls until EasyLocalization is re-enabled
extension StringTranslation on String {
  String tr() {
    // Hardcoded Spanish translations - synced with es-ES.json
    const translations = {
      // App
      'app.name': 'InmuFácil',
      
      // Home - Hero Section
      'home.hero_badge': 'Plataforma P2P Segura',
      'home.tagline_part1': 'Inmueble fácil ',
      'home.tagline_part2': 'entre particulares',
      'home.hero_title_line1': 'Sin intermediarios.',
      'home.hero_title_line2': '0% comisiones.',
      'home.hero_subtitle': 'Compra y vende sin comisiones.',
      'home.hero_feature_1': 'De la búsqueda a la notaría en pasos seguros.',
      'home.hero_feature_2': 'Elimina la incertidumbre.',
      
      // Home - Search Form
      'home.search_title': '¿Qué buscas?',
      'home.search_what_label': '¿Qué buscas?',
      'home.location_label': 'Ubicación',
      'home.location_placeholder': 'Madrid, Barcelona, Sevilla...',
      'home.search_location_label': 'Ubicación',
      'home.search_location_placeholder': 'Ciudad o Barrio',
      'home.price_range_label': 'Rango de Precio',
      'home.price_from': 'Desde',
      'home.price_to': 'Hasta',
      'home.search_button': 'Buscar Propiedades',
      'home.search_btn': 'Buscar Propiedades',
      
      // Home - Property Types
      'home.property_type_all': 'Todos',
      'home.property_type_apartment': 'Piso / Apartamento',
      'home.property_type_house': 'Casa / Chalet',
      'home.property_type_land': 'Terreno / Parcela',
      'home.property_type_office': 'Oficina / Local',
      'home.property_type_garage': 'Garaje',
      'home.property_type_new_construction': 'Obra Nueva',
      
      // Home - Trust Badges
      'home.guarantee_title': 'Garantía InmuFácil',
      'home.guarantee_subtitle': 'Tu venta tranquila',
      'home.verified_title': 'P2P Verificado',
      'home.verified_subtitle': 'Tu compra segura',
      
      // Home - Stats
      'home.properties_today': 'Propiedades hoy',
      'home.verified_this_week': 'Verificadas esta semana',
      
      // Home - Map
      'home.map_loading': 'Cargando mapa...',
      'home.map_error': 'Error al cargar el mapa',
      'home.location_permission_denied': 'Permiso de ubicación denegado',
      'home.reset_filters': 'Restablecer filtros',
      
      // Common
      'common.save': 'Guardar',
      'common.cancel': 'Cancelar',
      'common.delete': 'Eliminar',
      'common.edit': 'Editar',
      'common.loading': 'Cargando...',
      'common.error': 'Error',
      'common.success': 'Éxito',
      'common.confirm': 'Confirmar',
      'common.back': 'Volver',
      'common.next': 'Siguiente',
      'common.finish': 'Finalizar',
      'common.search': 'Buscar',
      'common.filter': 'Filtrar',
      'common.sort': 'Ordenar',
      
      // Not Found Screen
      'not_found.building_future_part1': 'Estamos construyendo el ',
      'not_found.building_future_part2': 'futuro entre particulares.',
      'not_found.description': 'Nuestros arquitectos digitales están asegurando cada ladrillo de código para que compres y vendas sin intermediarios.',
      'not_found.notify_me_label': '¿Quieres que te avisemos?',
      'not_found.email_placeholder': 'Tu correo electrónico',
      'not_found.notify_button': 'Avísame',
      'not_found.security_text': 'Tus datos están protegidos bajo cifrado de grado bancario.',
      'not_found.secure_infrastructure': 'Infraestructura Segura',
      'not_found.direct_architecture': 'Arquitectura Directa',
      'not_found.copyright_text': 'InmuFácil. Todos los derechos reservados.',
      'not_found.notify_me_success': '¡Gracias! Te avisaremos cuando estemos listos.',
    };
    
    return translations[this] ?? this;
  }
}
