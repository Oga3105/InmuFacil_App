---
description: Protocolo de Debate Arquitectónico - Análisis Multi-Agente antes de Ejecución
status: active
priority: high
---

# 🏛️ PROTOCOLO DE DEBATE ARQUITECTÓNICO

## 📋 Descripción

Este protocolo **OBLIGA** a realizar un análisis multi-agente antes de ejecutar cualquier cambio en el código. Previene errores por precipitación y asegura coherencia arquitectónica.

---

## 🎯 Objetivo

Evitar errores por precipitación y asegurar que cada cambio en el código mantenga la coherencia con el resto del proyecto (Home, Mapa, Listado, Docker, etc.).

---

## 🚫 PROHIBICIÓN ABSOLUTA

**Está PROHIBIDO** responder directamente con la solución o el código final sin seguir el flujo de 3 pasos.

---

## 📐 Flujo Obligatorio de 3 Pasos

### PASO 1: LA MESA REDONDA (Internal Monologue)

Antes de ejecutar nada, convoca a los agentes relevantes según el contexto y simula una breve discusión técnica:

**Agentes Disponibles:**
- **@Architect:** Plantea la estructura y la viabilidad
- **@Frontend:** Analiza impacto en UI/UX y componentes React/Flutter
- **@Backend:** Evalúa impacto en APIs, base de datos y servicios
- **@DevOps:** Considera deployment, Docker, CI/CD
- **@Security:** Identifica vulnerabilidades y riesgos de seguridad
- **@Critic (Tú):** Busca fallos, casos borde (edge cases) o inconsistencias
- **@Specialist:** (El agente ejecutor) Defiende su implementación técnica

**Formato del Debate:**
```
🏛️ MESA REDONDA ARQUITECTÓNICA

@Architect: [Análisis de estructura y viabilidad]
@Critic: [Identificación de fallos y casos borde]
@[Specialist]: [Defensa de implementación técnica]
@Security: [Evaluación de riesgos] (si aplica)
```

### PASO 2: EL PLAN CONSENSUADO

Presenta un resumen muy breve (bullet points) de lo acordado en el debate:

```
📋 PLAN CONSENSUADO

Tras analizar tu petición, hemos decidido:
1. Estrategia: [X]
2. Riesgos detectados: [Y]
3. Solución propuesta: [Z]
```

### PASO 3: EJECUCIÓN

**Solo después** de mostrar el plan, procede a generar los comandos, el código o la respuesta final.

---

## 🚦 SISTEMA DE SEMÁFORO (Traffic Light)

Para facilitar la visualización del estado de cada decisión, usa el siguiente sistema de semáforo:

### Códigos de Estado

- **🟢 VERDE** - Aprobado / Activo / Listo para proceder
  - Ejemplo: "🟢 Arquitectura validada"
  - Ejemplo: "🟢 Tests pasando"

- **🟡 AMARILLO** - Advertencia / Precaución / Requiere atención
  - Ejemplo: "🟡 Rendimiento a monitorear"
  - Ejemplo: "🟡 Dependencia externa"

- **🔴 ROJO** - Bloqueante / Crítico / No proceder
  - Ejemplo: "🔴 Breaking change detectado"
  - Ejemplo: "🔴 Vulnerabilidad de seguridad"

- **✅ CHECKMARK** - Completado / Verificado
  - Ejemplo: "✅ Código fusionado a develop"
  - Ejemplo: "✅ Tests implementados"

- **⏳ HOURGLASS** - En progreso / Pendiente
  - Ejemplo: "⏳ Esperando aprobación de usuario"
  - Ejemplo: "⏳ Implementación en curso"

- **❌ CROSS** - Rechazado / Fallido / No aplicable
  - Ejemplo: "❌ Propuesta descartada"
  - Ejemplo: "❌ Tests fallando"

### Ejemplo de Uso en Plan Consensuado

```
📋 PLAN CONSENSUADO

1. Estrategia: Reutilizar searchProvider existente
   🟢 Componente ya probado y estable
   
2. Riesgos detectados:
   🟡 Rendimiento con 1000+ propiedades (monitorear)
   🔴 No hay tests para este flujo (BLOQUEANTE)
   
3. Solución propuesta:
   ✅ Crear PriceSlider widget reutilizable
   ⏳ Implementar tests unitarios (pendiente)
   🟢 Usar debouncing para optimizar
```

---

## 🎯 Casos de Uso

### Cuándo Activar el Protocolo

✅ **SIEMPRE** para:
- Cambios en arquitectura
- Nuevas features
- Modificaciones en múltiples archivos
- Cambios en APIs o contratos
- Refactorizaciones significativas
- Cambios en configuración de Docker/CI/CD

❌ **NO NECESARIO** para:
- Correcciones de typos
- Cambios de formato/estilo
- Actualizaciones de documentación simple
- Fixes de bugs triviales (< 5 líneas)

---

## 📊 Ejemplo de Aplicación

**Usuario:** "Añade un filtro de precio en el mapa"

**PASO 1: MESA REDONDA**
```
🏛️ MESA REDONDA ARQUITECTÓNICA

@Architect: Necesitamos sincronizar el filtro de precio entre Home, Mapa y Listado.
            Propongo usar el searchProvider existente para mantener consistencia.

@Critic: ¿Qué pasa si el usuario cambia el precio en el mapa y luego va a Home?
         Debemos asegurar que el estado persista. También, ¿cómo afecta al
         rendimiento si hay 1000+ propiedades?

@Frontend: Puedo implementar un slider reutilizable. Necesito confirmar que
           el searchProvider ya tiene priceRange. También debo verificar que
           el mapa se actualice reactivamente.

@Backend: El endpoint /properties ya soporta min_price y max_price. No hay
          cambios necesarios en el backend.
```

**PASO 2: PLAN CONSENSUADO**
```
📋 PLAN CONSENSUADO

1. Estrategia: Reutilizar searchProvider.priceRange existente
2. Riesgos detectados: 
   - Persistencia de estado entre rutas
   - Rendimiento con muchas propiedades
3. Solución propuesta:
   - Crear PriceSlider widget reutilizable
   - Usar filteredByMapPropertiesProvider para filtrado reactivo
   - Añadir debouncing (300ms) para evitar requests excesivos
```

**PASO 3: EJECUCIÓN**
```dart
// Código del PriceSlider...
```

---

## 🛡️ Integración con Shield Protocol

Este protocolo se ejecuta **ANTES** del Shield Protocol:

1. **Debate Arquitectónico** → Diseño y plan
2. **Shield Protocol** → Validación de compilación
3. **Commit** → Solo si ambos pasan

---

## ✅ Confirmación de Activación

Al activar este protocolo, el agente debe responder:

> "✅ Protocolo de Debate Arquitectónico ACTIVADO. Analizaré cada una de tus palabras antes de escribir código."

---

## 📝 Registro de Debates

Todos los debates deben quedar registrados en:
- Artifacts de implementación (`implementation_plan_*.md`)
- Commits (en el mensaje, mencionar "Debate: [resumen]")
- PRs (incluir sección "Architectural Debate" si es relevante)

---

## 🔄 Actualización del Protocolo

Este protocolo puede evolucionar. Cambios deben ser aprobados por el usuario y documentados aquí.

**Última actualización:** 2026-02-12
**Versión:** 1.0
