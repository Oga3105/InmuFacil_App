# Visión del Proyecto InmuFácil

## Resumen Ejecutivo

**InmuFácil** es una plataforma P2P (Peer-to-Peer) revolucionaria que transforma el proceso de compraventa inmobiliaria, eliminando intermediarios tradicionales y empoderando a compradores y vendedores para gestionar sus transacciones de forma directa, transparente y eficiente.

**Filosofía Central:** *"Donde la tecnología reemplaza la confianza"*

---

## 🎯 Concepto Central: P2P Puro

### La Revolución del Modelo P2P

InmuFácil no es simplemente una plataforma de anuncios; es un **ecosistema P2P completo** donde:

- **La tecnología sustituye a las agencias**: Gemini AI + Cifrado de grado militar reemplazan la "confianza" que tradicionalmente proporcionaban los intermediarios
- **Verificación automatizada**: KYC (Know Your Customer) con validación de identidad elimina la necesidad de verificación manual
- **Seguridad por diseño**: Cada interacción está protegida por múltiples capas de seguridad
- **Transparencia total**: Blockchain-ready para trazabilidad completa de transacciones

### ¿Por qué P2P es el Futuro?

**Modelo Tradicional (Agencias):**
```
Vendedor → Agencia (3-5% comisión) → Comprador
         ↓
    Confianza basada en reputación
    Costes elevados
    Proceso opaco
```

**Modelo InmuFácil (P2P):**
```
Vendedor ←→ Plataforma (tecnología) ←→ Comprador
         ↓
    Confianza basada en criptografía
    Costes mínimos
    Proceso transparente
```

---

## 🛡️ Defensa en Profundidad (Defense in Depth)

InmuFácil implementa una estrategia de **seguridad multicapa** donde cada capa protege contra diferentes vectores de ataque:

### Capa 1: Perímetro (Escudo Anti-Agencias)
**Objetivo:** Mantener el ecosistema P2P puro
- 🚫 Bloqueo de 30+ dominios de agencias inmobiliarias
- 🔍 Detección de 40+ keywords profesionales
- 🛡️ Validación multi-factor para prevenir falsos positivos
- 📊 IP tracking y análisis de patrones

### Capa 2: Identidad (KYC Seguro)
**Objetivo:** Verificar identidad sin comprometer privacidad
- 📧 MFA por email (tokens 6 dígitos, 15 min expiration)
- 🖼️ Redacción automática de DNI (MRZ, Firma, Equipo Emisor)
- 🔐 Cifrado AES-256-GCM de datos personales
- ✅ Validación MIME para prevenir archivos maliciosos

### Capa 3: Datos (Cifrado at-Rest)
**Objetivo:** Proteger información sensible almacenada
- 🔒 AES-256-GCM con autenticación de integridad
- 🔑 PBKDF2 con 100,000 iteraciones para derivación de claves
- 🎲 IV único (12 bytes) por cada operación de cifrado
- 🚫 Zero-knowledge: La plataforma no puede leer datos cifrados

### Capa 4: Acceso (Brute Force Prevention)
**Objetivo:** Prevenir ataques de fuerza bruta
- ⚠️ Máximo 3 intentos fallidos
- ⏱️ Bloqueo temporal de 15 minutos
- 📊 Ventana deslizante de 30 minutos
- 🚨 Alertas MITRE T1110 en tiempo real

### Capa 5: Monitoreo (Audit & Observability)
**Objetivo:** Detectar y responder a incidentes
- 📝 Logs estructurados para SIEM
- 🔍 Filtros automáticos de datos sensibles
- 🎯 Eventos de seguridad con severidad
- ✅ Cumplimiento GDPR y PCI DSS

### Capa 6: Desarrollo (DevSecOps)
**Objetivo:** Seguridad desde el código
- 🔍 Pre-commit hooks (detección de secretos)
- 🧪 Tests de seguridad automatizados
- 📋 Code review obligatorio
- 🚀 CI/CD con validación de seguridad

---

## 📊 Estado Actual del Proyecto

### Hitos Completados ✅

**Hito 1: Estructura Base y Autenticación**
- ✅ Configuración Git Flow (main/develop)
- ✅ Modelos de datos con SQLAlchemy
- ✅ Hashing Bcrypt para contraseñas
- ✅ Schemas Pydantic con RLS

**Hito 2: Validación de Identidad (KYC Seguro)** 🔐
- ✅ Cifrado AES-256-GCM implementado
- ✅ MFA por email con tokens seguros
- ✅ Redacción automática de DNI
- ✅ Validación MIME y prevención brute force
- ✅ Escudo Anti-Agencias activo
- ✅ Audit logging sin datos sensibles

**Hito 3 / Misión 9: Autenticación Completa** 🔐
- ✅ Registro de Usuarios (Particular/Profesional)
- ✅ Login Seguro con JWT
- ✅ MFA V2 (Email Token)
- ✅ Recuperación de Contraseña


**Hito 4: Búsqueda y Filtrado (Search Engine)** ✅
- ✅ Algoritmo de filtrado combinatorio (Precio, Ubicación, Características)
- ✅ Optimización de consultas SQL (Query Builder dinámico)
- ✅ Prevención de SQL Injection en filtros

**Hito 5: Gestión de Visitas (Block Scheduling)** ✅
- ✅ Algoritmo de Visitas en Bloque (Slots automáticos)
- ✅ Dashboard de Estado (Requested, Approved, Completed)
- ✅ Control de Acceso basado en Roles (Owner vs Buyer)

**Hito 6: Ofertas Transparentes** ✅
- ✅ Modelo `PropertyOffer` transparente
- ✅ Prevención de auto-ofertas
- ✅ Estados de oferta gestionados (Pending, Accepted, Rejected)

**Hito 7: Negociación y Chat (Híbrido)** ✅
- ✅ Protocolo de Contraofertas
- ✅ Chat Encriptado (Fernet) activado bajo demanda
- ✅ Historial de negociación inmutable (Audit Log)

**Hito 8: Reserva y Señal (Payment Mock)** ✅
- ✅ Gestión de Pagos (Mock Provider)
- ✅ Bloqueo de Concurrencia (Idempotencia)
- ✅ Visibilidad Configurable (Ocultar al reservar)

**Hito 9: Verificación Documental (Compliance)** ✅
- ✅ Upload de Notas Simples con OCR
- ✅ Detección automática de Ref. Catastral
- ✅ Política de Retención de Datos
- ✅ Borrado seguro y anonimización

**Hito 10: Tasación (Valuation)** ✅
- ✅ Algoritmo de valoración comparativa
- ✅ Histórico de tasaciones
- ✅ Integración (Mock) con fuentes externas

**Hito 11: Financiación** ✅
- ✅ Perfiles hipotecarios y Scoring
- ✅ Simulación de cuotas en tiempo real
- ✅ Asignación de asesores financieros

**Hito 12: Contratos (Drafts)** ✅
- ✅ Generación PDF con ReportLab (Arras Penitenciales)
- ✅ Análisis de Contratos Propios con IA (Gemini)
- ✅ Cuestionario Legal para personalización de cláusulas

**Hito 13: Firma Digital** ✅
- ✅ Infraestructura de Firma Remota (Mock Provider Hexagonal)
- ✅ Tokens de un solo uso (One-Time Token)
- ✅ Trazabilidad del ciclo de vida de la firma

**Hito 14: Preparación Notarial** ✅
- ✅ Gestión de Notarios
- ✅ Generación de Dossier Seguro (Unmasking bajo demanda)
- ✅ Manifest de Integridad (SHA256)

### Próximo Hito 🎯

**Hito 15: Firma y Cierre Definitivo**
- Escritura Pública
- Entrega de Llaves
- Pago Final (Integración Bancaria)

---

## 🏗️ Los 15 Hitos de Compraventa

1. ✅ **Publicación de Inmueble** - El vendedor crea y publica su propiedad
2. ✅ **Búsqueda y Filtrado** - Compradores encuentran propiedades de interés
3. ✅ **Solicitud de Visita** - Compradores solicitan visitas a inmuebles
4. ✅ **Coordinación de Visitas en Bloque** - Sistema agrupa visitas eficientemente
5. ✅ **Realización de Visitas** - Dashboard de ejecución y estados seguros
6. ✅ **Manifestación de Interés** - Ofertas Transparentes formalizadas
7. ✅ **Negociación de Precio** - Protocolo de Contraofertas + Chat Encriptado
8. ✅ **Reserva del Inmueble** - Comprador reserva con señal y bloqueo
9. ✅ **Verificación Documental** - Validación de documentación legal (OCR + Cifrado)
10. ✅ **Tasación del Inmueble** - Valoración profesional del inmueble
11. ✅ **Solicitud de Hipoteca** - Gestión de financiación bancaria
12. ✅ **Elaboración de Contrato** - Generación de contrato de compraventa (Dinámico + Cuestionario)
13. ✅ **Firma de Arras** - Formalización del compromiso de compra (Firma Digital)
14. ✅ **Preparación Notarial** - Coordinación con notaría y Dossier Seguro (Unmasking)
15. ✅ **Control de Pasos (Timeline)** - Trazabilidad y Doble Confirmación de hitos financieros
16. 🔜 **Firma ante Notario** - Cierre definitivo de la transacción

---

## 💡 Modelo de "Visitas en Bloque"

Una de las innovaciones clave de InmuFácil es el sistema de **Visitas en Bloque**, que optimiza el tiempo tanto de vendedores como de compradores:

- **Agrupación Inteligente**: El sistema agrupa múltiples solicitudes de visita para un mismo inmueble en franjas horarias específicas
- **Eficiencia Temporal**: El vendedor organiza una única sesión de visitas en lugar de múltiples citas individuales
- **Transparencia**: Los compradores conocen que pueden coincidir con otros interesados, fomentando decisiones más ágiles
- **Flexibilidad**: Sistema de slots horarios que se adapta a la disponibilidad del vendedor

---

## 🎁 Propuesta de Valor

### Para Vendedores
- ✅ **Ahorro masivo**: Elimina comisiones del 3-5% (€6,000-€10,000 en un piso de €200,000)
- ✅ **Control total**: Gestión directa sin intermediarios
- ✅ **Seguridad garantizada**: Verificación KYC de todos los compradores
- ✅ **Eficiencia**: Visitas en bloque optimizan tiempo
- ✅ **Transparencia**: Visibilidad completa del proceso

### Para Compradores
- ✅ **Acceso directo**: Comunicación sin filtros con vendedores
- ✅ **Información verificada**: Documentación validada automáticamente
- ✅ **Proceso guiado**: 15 hitos claros hasta la firma
- ✅ **Seguridad**: Vendedores verificados con KYC
- ✅ **Herramientas**: Negociación y gestión documental integrada

---

## 🔧 Tecnología y Arquitectura

### Stack Tecnológico
- **Backend**: FastAPI 0.104.1 (Python) - API REST de alto rendimiento
- **Base de Datos**: SQLAlchemy 2.0.23 (SQLite dev, PostgreSQL prod)
- **Autenticación**: JWT + MFA Email + Bcrypt
- **Cifrado**: AES-256-GCM (Cryptography 41.0.7)
- **Procesamiento**: Pillow 10.1.0 (redacción de imágenes)
- **Validación**: Pydantic 2.5.0 con schemas seguros

### Principios de Diseño Activos

**Security by Design:**
- Seguridad considerada desde el diseño inicial
- Arquitectura de confianza cero (Zero Trust)
- Principio de mínimo privilegio

**Security by Default:**
- Configuración segura out-of-the-box
- Cifrado activado por defecto
- Logs sin datos sensibles automáticamente

**DevSecOps:**
- Shift Left: Seguridad en todas las fases
- Automatización de tests de seguridad
- CI/CD con validación continua

---

## 💰 Modelo de Negocio

- **Freemium**: Publicación básica gratuita para vendedores
- **Premium**: Funcionalidades avanzadas (destacados, análisis de mercado)
- **Servicios Adicionales**: Tasaciones, asesoría legal, gestión hipotecaria
- **Comisión por Éxito**: 0.5-1% solo en transacciones completadas (vs 3-5% de agencias)

**Ventaja Competitiva:** Costes 5-10x menores que agencias tradicionales

---

## 🌟 Visión a Futuro

InmuFácil aspira a convertirse en la plataforma de referencia para la compraventa inmobiliaria P2P en España, democratizando el acceso al mercado inmobiliario y reduciendo los costes de transacción para todos los participantes.

**Roadmap 2026-2027:**
- Q1 2026: Lanzamiento MVP con Hitos 1-5
- Q2 2026: Integración con notarías y bancos
- Q3 2026: Expansión a principales ciudades españolas
- Q4 2026: Blockchain integration para trazabilidad
- 2027: Expansión internacional (Portugal, Francia)

---

## 📜 Compliance y Certificaciones

- ✅ **GDPR**: Cifrado de datos personales, derecho al olvido
- ✅ **OWASP Top 10**: Mitigación completa
- ✅ **PCI DSS**: Cifrado at-rest, audit logging
- ✅ **ISO 27001**: Controles de seguridad implementados
- ✅ **MITRE ATT&CK**: Cobertura T1110, T1566, T1552, T1078

---

*Documento de Visión - InmuFácil Project*  
*Versión 8.0 - Enero 2026*  
*Actualizado con DevSecOps Standards - Hito 8 Completado*
