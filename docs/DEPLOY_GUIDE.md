# Guia de Deploy — InmuFacil

**Servidor:** `root@87.106.247.84`
**URL produccion:** `https://www.inmufacil.com/TFM/`

---

## FRONTEND

### Paso 1 — Construir

Desde `InmuFacil_Project/frontend` en PowerShell:

```powershell
flutter build web --release --base-href /TFM/
```

### Paso 2 — Subir al servidor

Desde `InmuFacil_Project/frontend` en PowerShell:

```powershell
scp -r build/web/* root@87.106.247.84:/opt/inmufacil/frontend/build/TFM/
```

### Paso 3 — Arreglar permisos y recargar nginx

```powershell
ssh root@87.106.247.84 "find /opt/inmufacil/frontend/build/TFM -type d -exec chmod 755 {} \; && find /opt/inmufacil/frontend/build/TFM -type f -exec chmod 644 {} \; && docker exec inmufacil_proxy nginx -s reload"
```

### Paso 4 — Limpiar cache del navegador

- Abre en modo incognito (`Ctrl+Shift+N`), o
- F12 → Application → Service Workers → Unregister → `Ctrl+Shift+R`

---

## BACKEND

### Paso 1 — Subir main.py (si se ha modificado)

Desde `InmuFacil_Project/` en PowerShell:

```powershell
scp backend/main.py root@87.106.247.84:/opt/inmufacil/backend/main.py
```

### Paso 2 — Subir otros archivos modificados

Si se han modificado archivos en `backend/src/`:

```powershell
scp backend/src/routes/nombre_archivo.py root@87.106.247.84:/opt/inmufacil/backend/src/routes/nombre_archivo.py
```

### Paso 3 — Reiniciar el contenedor

```powershell
ssh root@87.106.247.84 "docker restart inmufacil_backend"
```

### Paso 4 — Verificar que arranco correctamente

```powershell
ssh root@87.106.247.84 "docker logs inmufacil_backend --tail 20"
```

Debe mostrar al final:
```
[DB] Schema synchronized. PostgreSQL operativo.
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:8000
```

---

## NGINX (si se modifica la config)

Desde `InmuFacil_Project/` en PowerShell:

```powershell
scp nginx/conf.d/default.conf root@87.106.247.84:/opt/inmufacil/nginx/conf.d/default.conf
```

Verificar y recargar:

```powershell
ssh root@87.106.247.84 "docker exec inmufacil_proxy nginx -t && docker exec inmufacil_proxy nginx -s reload"
```

---

## DEPLOY COMPLETO (frontend + backend)

Cuando se toca tanto frontend como backend, ejecutar en este orden:

```
1. Subir backend (pasos 1-2)
2. Reiniciar backend (paso 3)
3. Verificar backend (paso 4)
4. Construir frontend (paso 1)
5. Subir frontend (paso 2)
6. Permisos + reload nginx (paso 3)
7. Limpiar cache navegador (paso 4)
```

---

## VERIFICACION RAPIDA

Comprobar que los tres contenedores estan corriendo:

```powershell
ssh root@87.106.247.84 "docker ps"
```

Deben aparecer:
- `inmufacil_backend` — Up
- `inmufacil_proxy` — Up
- `inmufacil_db` — Up

---

## NOTA: deploy.sh (alternativa automatica para frontend)

Desde `InmuFacil_Project/frontend` en Git Bash:

```bash
bash deploy.sh
```

Hace automaticamente: build → upload → permisos → reload nginx.
