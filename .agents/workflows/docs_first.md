---
description: "Documentación Primero — checklist obligatorio antes de todo git push o PR"
---

# Workflow 7 · Documentación Primero (`docs_first`)

> **Cuándo usarlo:** Antes de ejecutar `git push`, abrir un Pull Request o hacer merge a `main` / `develop`.
> Si algún paso falla, **NO continúes con el push/PR** hasta resolverlo.

---

## Paso 0 — Identificar el alcance del cambio

Ejecuta el siguiente comando para ver exactamente qué archivos han cambiado:

```bash
git diff --stat HEAD
git status
```

Anota mentalmente (o en el commit message) si el cambio afecta:
- [ ] **Backend** (modelos, rutas, schemas, lógica de negocio)
- [ ] **Frontend** (pantallas, widgets, providers, entidades)
- [ ] **Base de datos** (nuevos campos/tablas en `models.py` o schemas Pydantic)
- [ ] **Infraestructura / Docker** (docker-compose, Dockerfiles, variables de entorno)
- [ ] **APIs públicas** (nuevos endpoints o cambios en contratos)

---

## Paso 1 — Verificar ADRs existentes

Si el cambio introduce una **decisión arquitectónica nueva** (ej. nueva biblioteca, cambio de patrón, nueva estrategia de datos):

1. Revisa `docs/adrs/` para confirmar que no choca con un ADR ya aceptado.
2. Si el cambio contradice un ADR existente → **crea o actualiza el ADR** antes de continuar.
3. Nombra el nuevo ADR con el siguiente número disponible: `NNN_descripcion_corta.md`.

```
docs/adrs/NNN_descripcion_corta.md
```

Usa la plantilla estándar del proyecto (Estado, Fecha, Contexto, Decisión, Consecuencias).

---

## Paso 2 — Actualizar documentación afectada

Para cada área marcada en el Paso 0, verifica y actualiza el documento correspondiente:

| Área                    | Documento a revisar / actualizar                         |
|-------------------------|----------------------------------------------------------|
| Arquitectura general    | `docs/ARCHITECTURE.md`                                   |
| API / Endpoints         | `docs/API_REFERENCE.md`                                  |
| Base de datos / modelos | `docs/adrs/009_protocolo_integridad_db.md` + migraciones  |
| Contratos / flujos      | `docs/CONTRACTS.md` / `docs/STATE_MACHINE.md`            |
| Seguridad / RGPD        | `docs/SECURITY.md`                                       |
| Despliegue              | `docs/DEPLOYMENT_GUIDE.md`                               |
| Setup / Getting started | `docs/GETTING_STARTED.md`                                |
| Troubleshooting         | `docs/TROUBLESHOOTING.md`                                |
| Temas / Design System   | `docs/THEME_CUSTOMIZATION.md`                            |
| i18n / Traducciones     | `frontend/I18N_GUIDELINES.md`                            |

**Regla mínima:** Si cambias la firma de un endpoint, modelo o widget público → actualiza su doc. Sin excepción.

---

## Paso 3 — Revisar el README del módulo afectado

- Si modificaste `backend/` → revisa `backend/README.md`.
- Si modificaste `frontend/` → revisa `frontend/FLUTTER_SETUP.md`.
- Si modificaste la raíz del proyecto → revisa el `README.md` principal.

Actualiza las secciones "Features", "Setup" o "Known limitations" si aplica.

---

## Paso 4 — Verificar consistencia DB (si aplica)

Si el cambio afecta **modelos de base de datos** (nuevos campos, tablas, tipos):

1. Confirma que los cambios en `backend/src/schemas/` y `backend/models.py` son coherentes.
2. Genera el SQL de migración manual (`ALTER TABLE` / `CREATE TABLE`).
3. Documenta el SQL en el ADR correspondiente o en un fichero `migrations/YYYYMMDD_descripcion.sql`.
4. Verifica en el contenedor Postgres:
   ```bash
   docker exec -it inmufacil_postgres psql -U inmufacil_user -d inmufacil_db
   \d nombre_tabla
   ```

---

## Paso 5 — Confirmar el checklist final

Antes de hacer `git add` / `git commit` / `git push`, verifica mentalmente:

- [ ] Los docs afectados están actualizados (Paso 2 completo).
- [ ] El README del módulo está al día (Paso 3).
- [ ] Si hubo decisión arquitectónica → hay ADR creado o actualizado (Paso 1).
- [ ] Si hubo cambio de DB → hay SQL de migración documentado (Paso 4).
- [ ] El mensaje de commit sigue la convención del proyecto (`feat:`, `fix:`, `docs:`, `refactor:`, etc.).
- [ ] No hay secretos, tokens ni `.env` de producción en el diff (`git diff --stat`).

---

## Paso 6 — Ejecutar el push / abrir el PR

Solo si **todos los checks anteriores están marcados**, procede:

```bash
# Ejemplo de push a feature branch
git add <archivos relevantes>
git commit -m "feat(scope): descripción concisa del cambio

- Detalle 1
- Detalle 2"
git push origin feat/nombre-de-la-feature
```

Si abres un PR, incluye en la descripción:
- **Qué cambia** y **por qué**.
- **ADRs afectados** (si aplica).
- **Pasos para probar** el cambio.
- Referencia al **issue** o tarea si existe.

---

## Referencias rápidas

| Comando útil                                  | Propósito                              |
|-----------------------------------------------|----------------------------------------|
| `git diff HEAD -- docs/`                      | Ver qué docs han cambiado              |
| `git log --oneline -10`                       | Revisar commits recientes              |
| `docker exec -it inmufacil_postgres psql ...` | Verificar esquema DB                   |
| `ls docs/adrs/ \| tail -5`                     | Ver últimos ADRs                       |
