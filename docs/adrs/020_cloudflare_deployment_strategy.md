# ADR 020: Estrategia de Despliegue — Cloudflare + VPS + Docker

**Estado:** Aceptado (implementacion en progreso)
**Fecha:** 2026-03-22
**Autores:** @DevOps, @Architect, @Shield

---

## Contexto

InmuFacil necesita pasar de un entorno de desarrollo local (Docker Desktop en Windows) a un entorno de produccion publico accesible en internet. Los requisitos son:

- Dominio propio: `inmufacil.com` (principal)
- HTTPS obligatorio
- La app debe ser accesible en `inmufacil.com/TFM` (no en la raiz, para proteger el acceso durante el TFM)
- El backend API debe estar en `api.inmufacil.com`
- 5 dominios adicionales deben redirigir a `inmufacil.com`
- El sitio NO debe ser indexado publicamente por buscadores
- Coste de infraestructura minimo (proyecto TFM/academico)

---

## Decision

### Stack de despliegue

| Capa | Tecnologia | Justificacion |
|---|---|---|
| CDN + DNS + SSL | Cloudflare (plan gratuito) | SSL gestionado, proxy, DDoS protection, sin coste |
| Servidor | VPS Debian 12 | Coste bajo, control total, Docker compatible |
| Contenedores | Docker + Docker Compose | Mismo entorno local/produccion, facil despliegue |
| Reverse proxy | Nginx | Sirve Flutter Web estatico + proxy al backend |
| CI/CD | GitHub Actions (futuro) + deploy manual | Simplicidad para fase TFM |

### Configuracion DNS (Cloudflare)

- **Registrador:** IONOS — nameservers cambiados a Cloudflare (`hope.ns.cloudflare.com`, `rodney.ns.cloudflare.com`)
- **Zone ID:** `117f5abc1238908b73a3cea2c8b2bd6a`
- Registros A para raiz, www, api → IP del VPS con proxy Cloudflare activado

### Estructura de rutas en produccion

```
https://inmufacil.com/TFM  →  Flutter Web (build estatico via Nginx)
https://api.inmufacil.com  →  FastAPI backend (Docker, puerto 8000)
https://inmufacil.com/api  →  Alternativa: proxy en Nginx al backend
https://inmufacil.com      →  404 (no hay landing publica)
```

### Dominios adicionales

Los dominios `inmufacil.es`, `inmufacil.store`, `inmufacil.info`, `inmueblefacilentreparticulares.com`, `inmueblefacilentreparticulares.es` se configuran con reglas de redireccion 301 en Cloudflare hacia `https://inmufacil.com`. Esto centraliza el SEO (cuando se active) en un unico dominio.

### No indexacion

Durante la fase TFM, el sitio no debe aparecer en buscadores:
- Header HTTP: `X-Robots-Tag: noindex, nofollow`
- Archivo `robots.txt` con `Disallow: /`
- Cloudflare puede inyectar el header en todas las respuestas via Transform Rule

### SSL/TLS

- Cloudflare gestiona el certificado SSL de cara al usuario (HTTPS externo)
- Entre Cloudflare y el VPS: modo "Full" (Cloudflare verifica el certificado del origen)
- Certificado en el VPS: Let's Encrypt (certbot) o Cloudflare Origin Certificate

---

## Consecuencias

### Positivas
- **Seguridad:** Cloudflare absorbe DDoS, escaneos automaticos y ataques de fuerza bruta antes de llegar al VPS
- **Coste cero de SSL:** Cloudflare gestiona los certificados automaticamente
- **Un unico servidor:** Docker Compose simplifica la operacion (backend + db en mismo host)
- **Mismo docker-compose.yml en local y produccion:** Elimina discrepancias de entorno

### Negativas
- **Punto unico de fallo:** Si el VPS cae, toda la aplicacion cae. Aceptable para TFM
- **Cloudflare como intermediario de confianza:** Todo el trafico pasa por Cloudflare. Para datos muy sensibles, considerar cifrado de extremo a extremo
- **Nginx + Plesk:** Si el VPS usa Plesk, puede haber conflictos con la configuracion manual de Nginx. Resolver con cuidado

---

## Alternativas Consideradas

1. **Vercel (frontend) + Railway (backend)**
   - Considerado: Simple para proyectos pequenos
   - Rechazado: Coste mayor en produccion, menos control sobre la BD

2. **Heroku**
   - Rechazado: Elimino el plan gratuito, coste elevado

3. **AWS EC2 + CloudFront**
   - Rechazado: Complejidad de configuracion excesiva para un TFM

4. **Sin Cloudflare (VPS directo)**
   - Rechazado: Sin DDoS protection, certificados SSL manuales, mayor superficie de ataque
