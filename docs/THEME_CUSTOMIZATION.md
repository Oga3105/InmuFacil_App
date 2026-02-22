# Theme Customization

Guía de estilos, colores y tipografías para el Frontend multiplataforma en Flutter (`AppTheme`).

## Core Theme (`ThemeData` M3)
InmuFácil se caracteriza por su diseño enfocado a alto contraste y sensación "Premium" en el sector inmobiliario. Todos los componentes de UI deben derivar del archivo principal de tema.

- **Colores Corporativos**:
  - `ColorPrimary`: Azul marino corporativo dominante. Reemplaza el rojo genérico para inspirar confianza y profesionalidad.
  - `ColorSecondary`: Color perla dorado o blanco hueso para contrastes.
- **Tipografía**:
  - Reemplazo absoluto de fuentes predeterminadas por tipografías legibles y modernas como Inter o Poppins.
  - Uso estricto del bloque central de `TextTheme` de Material 3 (`displayLarge`, `bodyMedium`, `labelSmall`). No hardcodee tamaños a mano donde sea evitable.

## Reglas de Componentes (Protocolo Pixel-to-Code)
- **`PremiumButton`**: Utilícelo para operaciones primarias. Brinda un resplandor sútil de sombra color primario (glow drop shadow) en lugar de una elevación básica Material.
- **Micro-animaciones**: Transiciones de rutas con Fade/Scale; *hover states* habilitados para UX web.
- **Tarjetas Flotantes**: Cuentan con fondo `glassmorphism` parcial si se solapan en mapas, o elevaciones con sombras gris suave.
