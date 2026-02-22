# InmuFácil (Project Squadron)

Plataforma de "Inteligencia de Activos" y compraventa inmobiliaria directa, sin comisiones de agencia.
*Mobile-First* desarrollado con **Flutter**, potenciado por **FastAPI** y **PostgreSQL**.

## 📚 Documentación del Proyecto (Single Source of Truth)

La documentación estructurada del proyecto reside exclusivamente en la carpeta `/docs`.
Cualquier desviación de este estándar será corregida por el Agente **@Architect**.

- [Guía Rápida (Localhost)](docs/GETTING_STARTED.md)
- [Arquitectura General (Clean Architecture, Stack)](docs/ARCHITECTURE.md)
- [Guía de Despliegue (VPS + Docker + Cloudflare)](docs/DEPLOYMENT_GUIDE.md)
- [Referencia de API y Contratos](docs/API_REFERENCE.md)
- [Modelos de Datos Compartidos](docs/CONTRACTS.md)
- [Políticas de Seguridad y OWASP](docs/SECURITY.md)
- [Gestión de Secretos (.env)](docs/SECRETS.md)
- [Máquinas de Estado (Visitas y Ofertas)](docs/STATE_MACHINE.md)
- [Estrategia de Testing (Pytest, Widget Tests)](docs/TESTING_STRATEGY.md)
- [UI y Estilos (Theme Customization)](docs/THEME_CUSTOMIZATION.md)
- [Solución de Problemas (Troubleshooting)](docs/TROUBLESHOOTING.md)
- [Decision Records (ADR)](docs/ADR/)

## 🚀 Inicio Rápido

Para levantar el proyecto en tu entorno local, consulta la [Guía Rápida (GETTING_STARTED.md)](docs/GETTING_STARTED.md).

## 🏛️ Gobernanza del Escuadrón (AI Agents)

Este proyecto cuenta con un equipo automatizado bajo la jerarquía:
- **@Watcher:** Supervisor general, self-healing y control de flujos.
- **@Architect:** Cumplimiento de Clean Architecture y ADRs.
- **@Shield:** Seguridad, privacidad y OWASP.
- **@Jules:** Testing automatizado (QA).
- **@DevOps:** Infraestructura Docker y CI/CD.
- **@FrontendProxy:** Pixel-to-Code y directrices de UI/Riverpod.

---
> *NOTA: Las mecánicas del escuadrón y los protocolos de debate se rigen por los archivos ubicados en `.agent/rules/`.*
