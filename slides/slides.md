---
theme: default
title: "InmuFacil - TFM"
info: |
  InmuFacil - Plataforma P2P de Compraventa Inmobiliaria con Seguridad DevSecOps
  Trabajo Fin de Master
author: Oscar Gomez Alonso
keywords: inmobiliaria,p2p,devsecops,flutter,fastapi,ciberseguridad
exportFilename: inmufacil-tfm
colorSchema: dark
drawings:
  persist: false
transition: slide-left
mdc: true
---

<div style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%;">

<img src="/logo.png" style="width:110px; margin-bottom:20px; filter: drop-shadow(0 0 24px rgba(19,91,236,0.5));" />

<h1 style="border:none; font-size:2.8em;"><span style="color:#135BEC;">Inmu</span><span style="color:#16A34A;">F&aacute;cil</span></h1>

<p style="color:#94A3B8; margin-top:-12px; font-size:1em;">
Plataforma P2P de Compraventa Inmobiliaria con Seguridad DevSecOps
</p>

<div style="background:#1C3F73; padding:12px 28px; border-radius:10px; border:1px solid #234983; text-align:center; margin-top:16px;">
<span style="color:#60A5FA; font-weight:700;">Trabajo Fin de M&aacute;ster</span><br>
<span style="color:#fff; font-size:1.05em; font-weight:600;">&Oacute;scar G&oacute;mez Alonso</span>
</div>

<p style="color:#64748B; margin-top:16px; font-size:0.85em;">inmufacil.com</p>

</div>

---

# El Problema

### El mercado inmobiliario espa&ntilde;ol est&aacute; dominado por intermediarios que generan una sensaci&oacute;n de "intermediaci&oacute;n pasiva"
<div style="font-size:0.83em;">
<div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; margin-top:2px;">

<div style="background:#1C3F73; padding:2px 8px; border-radius:10px; border-left:3px solid #135BEC;">
<h3 style="margin-top:0; color:#60A5FA !important; font-size:0.95em;">Comprador</h3>
<div style="font-size:0.8em;">

- Paga un **3% adicional** (m&iacute;nimos de **3.000€ – 4.500€**) m&aacute;s posibles tarifas financieras de hasta **6.000€**
- **Esfuerzo:** realiza la b&uacute;squeda activa, filtra anuncios, verifica la zona y gestiona su propia log&iacute;stica de mudanza
</div>
</div>

<div style="background:#1C3F73; padding:2px 8px; border-radius:10px; border-left:3px solid #16A34A;">
<h3 style="margin-top:0; color:#16A34A !important; font-size:0.95em;">Vendedor</h3>
<div style="font-size:0.8em;">

- Paga entre el **3% y el 7%** a su agencia (m&iacute;nimos fijos de **7.260€ – 9.000€**)
- **Esfuerzo:** prepara la vivienda, realiza la limpieza, toma datos t&eacute;cnicos y atiende personalmente las visitas
</div>
</div>

<div style="background:#1C3F73; padding:2px 8px; margin-top:4px; border-radius:10px; border-left:3px solid #135BEC;">
<h3 style="margin-top:0; color:#60A5FA !important; font-size:0.95em;">En una vivienda de 250.000 EUR</h3>
<div style="font-size:0.8em;">

- Vendedor: **7.500 - 15.000 EUR** en comisiones
- Comprador: hasta **7.500 EUR** adicionales
- **Total entre ambos: 15.000 - 22.500 EUR que se quedan las agencias**
</div>
</div>

</div>

- **Intermediaci&oacute;n Pasiva.** La agencia se limita a la publicaci&oacute;n pasiva en portales que ya conocen y la gesti&oacute;n documental b&aacute;sica, cobrando honorarios de "servicio completo" por un trabajo realizado mayoritariamente por los particulares
- **Falta de Transparencia.** El vendedor **no conoce las ofertas reales que llegan** y ambas partes **nunca hablan directamente** hasta fases muy avanzadas
- **Barrera Tecnol&oacute;gica.** Los portales actuales no reemplazan la confianza, la obligan a trav&eacute;s de contratos de exclusividad

</div>

> *&laquo;&iquest;Y si la tecnolog&iacute;a pudiera reemplazar la confianza que aporta una agencia?&raquo;*

---

# La Soluci&oacute;n

### InmuF&aacute;cil: donde la tecnolog&iacute;a reemplaza la confianza

<br>

Una plataforma **peer-to-peer** que permite a particulares comprar y vender propiedades **sin intermediarios**, sustituyendo la confianza tradicional por:

| Funci&oacute;n | Tecnolog&iacute;a |
|---------|-----------|
| Verificaci&oacute;n de identidad | KYC automatizado + redacci&oacute;n PII |
| Protecci&oacute;n de datos | Cifrado AES-256-GCM (Vault) |
| Detecci&oacute;n de fraude | Active Intelligence Shield 2.0 (IA + OSINT) |
| Comunicaci&oacute;n segura | Chat P2P cifrado (Fernet) |
| Proceso legal guiado | Asistente IA paso a paso |

---

# Stack Tecnol&oacute;gico

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:12px;">

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983;">
<h3 style="margin-top:0; color:#60A5FA !important;">Backend</h3>
<div style="font-size:0.82em;">

- **FastAPI** (Python 3.13)
- **PostgreSQL 15** (Docker)
- **SQLAlchemy 2.0** + **Pydantic v2**
- **Gemini AI** (Vision + Asistente)
- **AES-256-GCM** (cryptography)
- **ReportLab** (PDF contratos)
</div>
</div>

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983;">
<h3 style="margin-top:0; color:#16A34A !important;">Frontend</h3>
<div style="font-size:0.82em;">

- **Flutter** (Web + Android)
- **Riverpod 3** (Estado reactivo)
- **GoRouter 17** (Navegaci&oacute;n)
- **Dio** (HTTP + JWT interceptors)
- **flutter_map** (OpenStreetMap)
- **easy_localization** (9 idiomas)
</div>
</div>

</div>

<div style="background:#1C3F73; padding:10px 16px; border-radius:10px; border:1px solid #234983; margin-top:12px; text-align:center; font-size:0.85em;">
<strong>Docker Compose</strong> &middot; <strong>Nginx</strong> reverse proxy &middot; <strong>Cloudflare</strong> DNS + SSL &middot; <strong>VPS Debian 12</strong>
</div>

---

# Arquitectura del Sistema

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:12px;">

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983; text-align:center; font-size:0.82em;">
<div style="color:#60A5FA; font-weight:700; margin-bottom:10px;">INFRAESTRUCTURA</div>
<div style="background:#234983; padding:6px; border-radius:6px; margin-bottom:6px;">Cloudflare (DNS + SSL + WAF)</div>
<div style="color:#64748B;">&darr;</div>
<div style="background:#234983; padding:6px; border-radius:6px; margin:6px 0;">Nginx (Reverse Proxy)</div>
<div style="display:flex; gap:6px;">
<div style="background:#135BEC; padding:6px; border-radius:6px; flex:1; color:#fff;">Flutter Web</div>
<div style="background:#16A34A; padding:6px; border-radius:6px; flex:1; color:#fff;">FastAPI</div>
</div>
<div style="color:#64748B; margin-top:6px;">&darr;</div>
<div style="background:#234983; padding:6px; border-radius:6px; margin-top:6px;">PostgreSQL 15 (Docker)</div>
</div>

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983; font-size:0.82em;">
<div style="color:#60A5FA; font-weight:700; margin-bottom:10px;">CLEAN ARCHITECTURE</div>

**presentation/** &rarr; screens, providers, widgets

**domain/** &rarr; entities, usecases

**data/** &rarr; repositories, datasources

<div style="color:#16A34A; font-weight:700; margin:12px 0 6px;">BACKEND MODULAR</div>

17 routers: auth, properties, visits, offers, negotiation, contracts, signature, notary, closing, post-sales...
</div>

</div>

---

# Seguridad: DevSecOps

<div style="color:#60A5FA; font-weight:600; margin:8px 0 12px;">
Security by Design &middot; Security by Default &middot; Defense in Depth
</div>

| Capa | Implementaci&oacute;n |
|------|---------------|
| **Cifrado at-rest** | AES-256-GCM con Vault (PBKDF2 100K iteraciones) |
| **Cifrado en tr&aacute;nsito** | TLS 1.3 v&iacute;a Cloudflare |
| **Hashing** | Bcrypt con salt autom&aacute;tico |
| **Autenticaci&oacute;n** | JWT + MFA por email + Google OAuth |
| **Autorizaci&oacute;n** | RBAC en todos los endpoints |
| **Validaci&oacute;n** | Pydantic v2 (anti-injection) |
| **Headers** | X-Content-Type-Options, X-Frame-Options, CSP |
| **CORS** | Or&iacute;genes espec&iacute;ficos (NO wildcards) |

---

# Escudo Anti-Agencias

<div style="color:#60A5FA; font-weight:600; margin:8px 0 12px;">
3 capas de defensa para mantener el ecosistema P2P puro
</div>

<div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:10px; font-size:0.82em;">

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-top:3px solid #F59E0B;">
<div style="color:#F59E0B; font-weight:700; margin-bottom:6px;">Layer 1 &mdash; Est&aacute;tico</div>

- Email corporativo
- Nombre de empresa
- Patrones conocidos
- Bloqueo + alerta SMTP
</div>

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-top:3px solid #F97316;">
<div style="color:#F97316; font-weight:700; margin-bottom:6px;">Layer 2 &mdash; IA + OSINT</div>

- Investigaci&oacute;n OSINT
- Scoring 0-100
- An&aacute;lisis Gemini
- Alerta si score > 90
</div>

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-top:3px solid #EF4444;">
<div style="color:#EF4444; font-weight:700; margin-bottom:6px;">Layer 3 &mdash; Comunidad</div>

- Denuncias P2P
- Categor&iacute;as predefinidas
- Umbral 3 denuncias
- Watermark trazabilidad
</div>

</div>

---

# Vault de Cifrado

<div style="color:#60A5FA; font-weight:600; margin:8px 0 12px;">
Protecci&oacute;n de datos sensibles &mdash; GDPR Compliance
</div>

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px;">

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983; text-align:center; font-size:0.82em;">
<div style="background:#234983; padding:6px; border-radius:6px; margin-bottom:6px;">Master Key (32 bytes, base64)</div>
<div style="color:#64748B;">&darr; PBKDF2 (100K iteraciones)</div>
<div style="background:#234983; padding:6px; border-radius:6px; margin:6px 0;">Derived Key</div>
<div style="color:#64748B;">&darr; AES-256-GCM</div>
<div style="display:flex; gap:6px; margin-top:6px;">
<div style="background:#135BEC; padding:6px; border-radius:6px; flex:1; color:#fff;">DNI cifrado</div>
<div style="background:#135BEC; padding:6px; border-radius:6px; flex:1; color:#fff;">Tel&eacute;fono cifrado</div>
</div>
</div>

<div style="font-size:0.88em;">

- **Fail-Safe Startup**: La app NO arranca sin clave v&aacute;lida
- **Zero-Log Policy**: Datos sensibles nunca en logs
- **Redacci&oacute;n PII**: MRZ, firma, equipo emisor (170K+ p&iacute;xeles verificados)
- **Derecho al Olvido**: Borrado seguro t&eacute;cnicamente viable
</div>

</div>

---

# KYC y Verificaci&oacute;n de Identidad

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:12px;">

<div>
<div style="color:#60A5FA; font-weight:600; margin-bottom:10px;">Proceso automatizado</div>

1. **Subida de documento** (DNI / Pasaporte)
2. **Gemini Vision** extrae datos del documento
3. **Ocultaci&oacute;n autom&aacute;tica de datos sensibles** en las im&aacute;genes almacenadas (MRZ, firma, n&uacute;mero de serie)
4. **Cifrado AES-256-GCM** del documento
5. **Almacenamiento seguro** en Vault
</div>

<div>
<div style="color:#16A34A; font-weight:600; margin-bottom:10px;">Resultado</div>

<div style="background:#1C3F73; padding:14px; border-radius:10px; border:1px solid #234983; font-size:0.88em;">

- Usuario verificado con **badge visible**
- Vendedores verificados = **mayor confianza**
- Compradores verificados = **Solvency Passport**
- Cumplimiento **GDPR** total
</div>
</div>

</div>

---

# Flujo Completo de Compraventa

<div style="display:flex; flex-wrap:wrap; gap:6px; justify-content:center; margin-top:16px;">
<div style="background:#135BEC; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">1. Publicar</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#135BEC; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">2. Buscar</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#135BEC; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">3. Visitar</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#135BEC; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">4. Ofertar</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#16A34A; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">5. Negociar</div>
</div>

<div style="display:flex; flex-wrap:wrap; gap:6px; justify-content:center; margin-top:8px;">
<div style="background:#16A34A; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">6. Reservar</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#16A34A; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">7. Contrato</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#16A34A; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">8. Firma</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#F59E0B; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">9. Notar&iacute;a</div>
<div style="color:#64748B; display:flex; align-items:center;">&rarr;</div>
<div style="background:#F59E0B; padding:8px 14px; border-radius:6px; color:#fff; font-weight:600; font-size:0.8em;">10. Cierre</div>
</div>

<div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; font-size:0.75em; text-align:center; margin-top:16px;">
<div style="background:#1C3F73; padding:8px; border-radius:6px;">
<span style="color:#135BEC; font-weight:600;">Verificaci&oacute;n IA</span><br>Smart Scheduling<br>Chat cifrado
</div>
<div style="background:#1C3F73; padding:8px; border-radius:6px;">
<span style="color:#16A34A; font-weight:600;">Contraofertas</span><br>PDF + Gemini<br>OTP Firma digital
</div>
<div style="background:#1C3F73; padding:8px; border-radius:6px;">
<span style="color:#F59E0B; font-weight:600;">Dossier ZIP</span><br>SHA-256 Manifest<br>Post-venta (ITP)
</div>
</div>

---

# Frontend: 50+ Pantallas

<div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:12px;">

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-left:3px solid #135BEC;">
<h3 style="margin-top:0; color:#60A5FA !important; font-size:0.95em;">Comprador</h3>
<div style="font-size:0.8em;">

- Mapa interactivo (OpenStreetMap)
- B&uacute;squeda con filtros avanzados
- Comparador de propiedades
- Chat P2P con acciones r&aacute;pidas
- Calendario de visitas
- Timeline de ofertas/negociaci&oacute;n
- Solvency Passport
- Firma digital + Notar&iacute;a
</div>
</div>

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-left:3px solid #16A34A;">
<h3 style="margin-top:0; color:#16A34A !important; font-size:0.95em;">Vendedor</h3>
<div style="font-size:0.8em;">

- Wizard de publicaci&oacute;n (5 pasos)
- Descripci&oacute;n generada con IA
- Dashboard de rendimiento
- Gesti&oacute;n de visitas (aprobar/rechazar)
- Gesti&oacute;n de ofertas
- Cuestionario legal (arras)
- Generaci&oacute;n de contrato PDF
- Post-venta (ITP, suministros)
</div>
</div>

</div>

<div style="text-align:center; margin-top:10px; color:#94A3B8; font-size:0.85em;">
Internacionalizaci&oacute;n: <strong style="color:#fff;">9 idiomas</strong> &mdash; ES, EN-US, EN-GB, EN-CA, FR-FR, FR-CA, CA, EU, GL
</div>

---

# Inteligencia Artificial (Gemini)

<div style="color:#60A5FA; font-weight:600; margin:4px 0 8px;">
13 integraciones con Gemini AI &mdash; <span style="color:#4ADE80;">9 activas</span> + <span style="color:#94A3B8;">4 preparadas (backend listo)</span>
</div>

<div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; font-size:0.72em;">

<div style="background:#1C3F73; padding:12px; border-radius:10px; border:1px solid #234983;">

| Funcionalidad | Estado |
|--------------|--------|
| **Descripci&oacute;n inmueble** | <span style="color:#4ADE80;">Activa</span> |
| **KYC / Vision** | <span style="color:#4ADE80;">Activa</span> |
| **Nota Simple OCR** | <span style="color:#4ADE80;">Activa</span> |
| **Contratos arras** | <span style="color:#4ADE80;">Activa</span> |
| **OSINT Shield** | <span style="color:#4ADE80;">Activa</span> |
| **Precio de mercado** | <span style="color:#4ADE80;">Activa</span> |

</div>

<div style="background:#1C3F73; padding:12px; border-radius:10px; border:1px solid #234983;">

| Funcionalidad | Estado |
|--------------|--------|
| **&Iacute;ndice de confort** | <span style="color:#4ADE80;">Activa</span> |
| **Barrios gemelos** | <span style="color:#4ADE80;">Activa</span> |
| **Descripci&oacute;n IA** | <span style="color:#4ADE80;">Activa</span> |
| **Validador de precio** | <span style="color:#94A3B8;">Preparada</span> |
| **Market Gap** | <span style="color:#94A3B8;">Preparada</span> |
| **Crecimiento urbano** | <span style="color:#94A3B8;">Preparada</span> |
| **Gu&iacute;as legales** | <span style="color:#94A3B8;">Preparada</span> |

</div>

</div>

<div style="background:#1C3F73; padding:10px 16px; border-radius:10px; border:1px solid #234983; margin-top:8px; font-size:0.78em;">
<span style="color:#16A34A; font-weight:700;">Consentimiento RGPD (Art. 6.1.a)</span> &mdash;
Popup expl&iacute;cito antes de cualquier procesamiento con IA &middot; Trust Dashboard (Bronze / Silver / Gold) &middot; El usuario controla qu&eacute; datos comparte
</div>

---

# OWASP Top 10 &mdash; Mitigaciones

<div style="font-size:0.78em; margin-top:12px;">

| # | Amenaza | Mitigaci&oacute;n en InmuF&aacute;cil |
|---|---------|------------------------|
| A01 | Broken Access Control | RBAC en todos los endpoints, anti-auto-oferta |
| A02 | Cryptographic Failures | AES-256-GCM, TLS 1.3, Bcrypt |
| A03 | Injection | Pydantic v2, SQLAlchemy parameterizado |
| A04 | Insecure Design | Security by Design, threat modeling |
| A05 | Security Misconfiguration | CORS estricto, headers de seguridad |
| A06 | Vulnerable Components | Dependabot + CodeQL automatizados |
| A07 | Auth Failures | JWT + MFA + rate limiting + bloqueo temporal |
| A08 | Data Integrity Failures | SHA-256 manifest en dossier notarial |
| A09 | Logging Failures | Audit logging, Zero-Log PII |
| A10 | SSRF | Validaci&oacute;n de URLs, no fetch externo arbitrario |

</div>

---

# MITRE ATT&CK &mdash; Defensa Proactiva

<br>

| T&eacute;cnica | ID | Mitigaci&oacute;n |
|---------|----|-----------|
| Brute Force | T1110 | Rate limiting + bloqueo temporal de cuenta |
| Phishing | T1566 | Validaci&oacute;n MIME de archivos subidos |
| Unsecured Credentials | T1552 | Cifrado at-rest + Vault + Zero-Log |
| Valid Accounts | T1078 | MFA por email obligatorio |
| Data from Local System | T1005 | Redacci&oacute;n autom&aacute;tica de PII en im&aacute;genes |

<div style="background:#1C3F73; padding:12px 16px; border-radius:10px; border:1px solid #234983; margin-top:16px; font-size:0.85em;">
<span style="color:#60A5FA; font-weight:700;">Capas adicionales: </span>
<strong>CodeQL</strong> (an&aacute;lisis est&aacute;tico en cada push) &middot;
<strong>Pre-commit hooks</strong> (detecci&oacute;n de secretos) &middot;
<strong>Community Shield</strong> (detecci&oacute;n social)
</div>

---

# DevOps y CI/CD

<div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:12px;">

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-left:3px solid #135BEC;">
<h3 style="margin-top:0; color:#60A5FA !important; font-size:0.95em;">Pipeline</h3>
<div style="font-size:0.82em;">

- **Git Flow**: feature branches + PRs
- **Pre-commit hooks**: secretos, linting
- **CodeQL**: an&aacute;lisis seguridad Python
- **Dependabot**: Python, Flutter, Actions
- **Deploy scripts**: automatizados
</div>
</div>

<div style="background:#1C3F73; padding:14px; border-radius:10px; border-left:3px solid #16A34A;">
<h3 style="margin-top:0; color:#16A34A !important; font-size:0.95em;">Infraestructura</h3>
<div style="font-size:0.82em;">

- **Docker Compose**: backend + PG + Nginx
- **Nginx**: reverse proxy + static files
- **Cloudflare**: DNS + SSL/TLS + WAF
- **VPS Debian 12**: producci&oacute;n operacional
</div>
</div>

</div>

<div style="background:#1C3F73; padding:10px 16px; border-radius:10px; border:1px solid #234983; margin-top:12px; text-align:center; font-size:0.82em;">
<strong>git push</strong> &rarr; Pre-commit hooks &rarr; CodeQL &rarr; Deploy script &rarr; Docker build &rarr; Cloudflare cache purge
</div>

---

# Demo en Vivo

<div style="text-align:center; margin-top:24px;">

<div style="display:flex; align-items:center; justify-content:center; gap:16px;">
<img src="/logo.png" style="width:70px; filter: drop-shadow(0 0 16px rgba(19,91,236,0.5));" />
<div style="font-size:2em; font-weight:800;">
<span style="color:#135BEC;">Inmu</span><span style="color:#16A34A;">F&aacute;cil</span>
</div>
</div>

<div style="font-size:1.3em; color:#94A3B8; margin-top:8px;">inmufacil.com</div>

</div>

<div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:24px; font-size:0.88em;">

<div style="background:#1C3F73; padding:14px; border-radius:10px; border:1px solid #234983;">

1. Registro de usuario
2. Verificaci&oacute;n KYC
3. Publicar inmueble con IA
</div>

<div style="background:#1C3F73; padding:14px; border-radius:10px; border:1px solid #234983;">

4. B&uacute;squeda en mapa + filtros
5. Oferta y negociaci&oacute;n
6. Compartir v&iacute;a WhatsApp
</div>

</div>

---

# M&eacute;tricas del Proyecto

<div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:16px;">

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983;">

| M&eacute;trica | Valor |
|---------|-------|
| Hitos backend | **17 / 17** |
| Pantallas frontend | **50+** |
| Idiomas soportados | **9** |
| Routers API | **17** |
</div>

<div style="background:#1C3F73; padding:16px; border-radius:10px; border:1px solid #234983;">

| M&eacute;trica | Valor |
|---------|-------|
| ADRs documentados | **22+** |
| Cifrado | **AES-256-GCM** |
| OWASP Top 10 | **10/10** |
| Compliance | **GDPR, PCI, ISO** |
</div>

</div>

<div style="text-align:center; margin-top:16px;">
<span style="color:#94A3B8;">Repositorio:</span> <strong>github.com/Oga3105/InmuFacil_App</strong> <span style="color:#94A3B8;">(branch: develop)</span>
</div>

---

# Conclusiones

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:16px;">

<div>
<div style="color:#16A34A; font-weight:700; margin-bottom:10px;">Lo conseguido</div>

- Plataforma **funcional y desplegada** en producci&oacute;n
- Proceso completo de compraventa **sin intermediarios**
- Seguridad **DevSecOps real**, no te&oacute;rica
- IA integrada de forma **&uacute;til y &eacute;tica** (RGPD)
- Escudo Anti-Agencias **&uacute;nico en el mercado**
</div>

<div>
<div style="color:#60A5FA; font-weight:700; margin-bottom:10px;">Aprendizajes clave</div>

- Security by Design desde el d&iacute;a 1 cambia la arquitectura
- La confianza entre desconocidos se construye con tecnolog&iacute;a
- Un MVP completo es m&aacute;s valioso que una idea perfecta sin ejecutar
</div>

</div>

---

<div style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100%;">

<img src="/logo.png" style="width:90px; margin-bottom:20px; filter: drop-shadow(0 0 20px rgba(19,91,236,0.4));" />

<h1 style="border:none; font-size:2.5em;">Gracias</h1>

<div style="font-size:1.15em; font-weight:600; color:#ffffff; margin-top:8px;">
&Oacute;scar G&oacute;mez Alonso
</div>

<div style="display:flex; gap:24px; color:#94A3B8; margin-top:16px;">
<span>inmufacil.com</span>
<span>&middot;</span>
<span>github.com/Oga3105/InmuFacil_App</span>
</div>

</div>
