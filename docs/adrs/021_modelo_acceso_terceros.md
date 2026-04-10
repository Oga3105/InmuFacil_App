# ADR 021: Modelo de Acceso para Terceros (Profesionales de Servicio)

**Estado:** Aceptado — Fase 1 implementada (Opcion A)
**Fecha:** 2026-04-10
**Autores:** @Architect, @Shield, @DevOps

---

## Contexto

InmuFacil es una plataforma P2P de compraventa inmobiliaria entre particulares. El modelo de negocio
requiere la participacion de un tercer perfil de usuario — llamado **Tercero** — que facilita servicios
necesarios para que la compraventa se lleve a cabo: tasadores, notarios, gestores, inspectores
tecnicos, asesores hipotecarios, etc. Los agentes inmobiliarios estan explicitamente vetados.

Hasta este ADR, el sistema incluia una pantalla de onboarding (`/onboarding/user-type`) donde el
usuario se auto-declaraba "Particular" o "Profesional" tras aceptar el GDPR. Este modelo presenta
un problema estructural de control de acceso: cualquier usuario puede reclamar el rol de profesional
sin ninguna validacion ni autorizacion externa.

La decision que se documenta aqui reemplaza ese modelo por un sistema controlado por administradores.

---

## Decision

### Cambios inmediatos (en cualquier caso)

1. **Eliminar la pantalla `/onboarding/user-type`** y toda su logica de auto-seleccion de rol.
2. **Todo nuevo usuario se registra siempre como `particular`**, independientemente del canal
   (email/password o Google OAuth).
3. **El backend deja de aceptar `user_type` como campo enviable por el cliente** durante el
   registro o el flujo de Google OAuth.
4. **El filtro anti-agencias** pierde la rama `user_type == "profesional"` (ya no aplica).
5. **El flujo GDPR** redirige directamente a `/` (home) tras la aceptacion.

### Modelo de acceso elegido: Opcion A — Invitacion por Token

El acceso al rol `tercero` solo puede ser concedido por un superadministrador mediante un
**enlace de invitacion firmado y de un solo uso**.

#### Mecanismo

```
Superadmin genera token → URL /register?invite=<TOKEN_FIRMADO>
                                         ↓
                              Usuario abre el enlace
                                         ↓
                       Registro normal (nombre, email, password)
                                         ↓
               Backend valida token: firma, caducidad, no-usado-antes
                                         ↓
                    User creado con user_type = 'tercero'
                                         ↓
                          Token marcado como consumido
```

#### Propiedades del token de invitacion

- Firmado con HMAC-SHA256 usando `SECRET_KEY` del servidor
- Payload: `{email_hint?, role: 'tercero', exp: timestamp, jti: uuid}`
- TTL configurable (por defecto 72 horas)
- De un solo uso: se marca como `used=True` en BD al consumirse
- Opcionalmente puede pre-fijar el email permitido (`email_hint`)

#### Tabla de invitaciones (a implementar)

```sql
CREATE TABLE invitations (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash  VARCHAR(64) UNIQUE NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'tercero',
    email_hint  VARCHAR(255),
    created_by  INTEGER REFERENCES users(id),
    used_by     INTEGER REFERENCES users(id),
    used_at     TIMESTAMP,
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP DEFAULT now()
);
```

#### Endpoints a implementar (Fase A)

| Metodo | Ruta | Acceso | Descripcion |
|--------|------|--------|-------------|
| `POST` | `/admin/invitations` | superadmin | Genera un token de invitacion |
| `GET`  | `/invitations/validate?token=...` | publico | Valida que el token es valido y no caducado |
| `POST` | `/auth/register` | publico | Acepta `invite_token` opcional; si valido, asigna rol `tercero` |

---

## Opciones Consideradas

### Opcion A — Invitacion por Token (ELEGIDA)

El administrador genera un enlace unico con token firmado. El usuario se registra a traves de ese
enlace y el sistema le asigna automaticamente el rol `tercero`.

- **Pros:** Control total. Cero friccion para el usuario final. Sin dashboard de aprobaciones complejo.
  Implementacion acotada. Trazabilidad completa de quien invito a quien.
- **Contras:** El admin debe generar manualmente un enlace por cada tercero. No escala bien con
  volumen alto.
- **Caso de uso optimo:** Fase inicial con pocos terceros (< 50). Operacion manual asumible.
- **Estado:** Elegida para Fase 1.

---

### Opcion B — Solicitud + Aprobacion por Admin

Los terceros potenciales rellenan un formulario de solicitud de acceso profesional (nombre,
empresa, tipo de servicio, numero de colegiacion). El admin ve las solicitudes en su dashboard y
aprueba o rechaza. Al aprobar, el usuario recibe un email con credenciales o link de activacion.

- **Pros:** Escalable. Rastro de solicitudes. El tercero puede expresar interes sin bloquear al admin.
- **Contras:** Requiere dashboard de admin funcional para gestion de solicitudes. Mayor complejidad.
- **Caso de uso optimo:** Cuando el volumen de terceros crezca y la gestion por token sea inmanejable.
- **Estado:** Pendiente de evaluacion para Fase 2.

---

### Opcion C — Portal Profesional Separado

App para particulares y portal para terceros son entornos distintos, posiblemente en subdominios
distintos (`pro.inmufacil.com`). El registro en el portal incluye verificacion de documentacion
profesional y aprobacion admin antes de activar la cuenta.

- **Pros:** Separacion de preocupaciones total. UX diferenciada. El particular nunca ve el portal de
  terceros.
- **Contras:** Dos frontends que mantener. Mayor coste de desarrollo e infraestructura.
- **Caso de uso optimo:** Cuando el volumen y complejidad del panel de terceros justifique una
  aplicacion propia.
- **Estado:** Descartada para fase actual. Reconsiderar si el dashboard de terceros crece
  significativamente.

---

### Opcion D — Alta Directa por Superadmin (Sin Autoservicio)

Solo el superadmin puede crear cuentas de tercero desde el panel. El tercero no tiene flujo de
registro propio: recibe un email con credenciales generadas por el admin.

- **Pros:** Maximo control. El tercero nunca tiene iniciativa en el proceso.
- **Contras:** Alta carga operativa. El admin es el cuello de botella para cada nuevo tercero.
  No escala. Sin trazabilidad de interes por parte del tercero.
- **Caso de uso optimo:** Beta cerrada con 3-5 colaboradores maximos.
- **Estado:** Descartada. La Opcion A ofrece el mismo control con menor friccion operativa.

---

## Consecuencias

### Positivas
- **Control de acceso real:** Ningun usuario puede auto-asignarse el rol de tercero.
- **UX simplificada para particulares:** El onboarding queda en una sola pantalla (GDPR) y acceden
  directamente al home. Sin preguntas de perfil.
- **Seguridad:** El backend ya no acepta `user_type` como campo cliente-enviable. El rol solo
  puede asignarse via codigo de servidor al validar el token de invitacion.
- **Trazabilidad:** Cada tercero en el sistema tiene un registro de quien lo invito y cuando.

### Negativas
- **Dependencia del admin:** Ninguna incorporacion de terceros es posible sin accion del admin.
  Aceptable en la fase actual.
- **Implementacion pendiente:** El mecanismo de tokens (tabla `invitations`, endpoints admin,
  validacion en registro) aun no esta implementado. Hasta que se implemente, el rol `tercero`
  no puede asignarse a ningun usuario desde el flujo normal.

---

## Deuda Tecnica Registrada

| Item | Descripcion | Prioridad |
|------|-------------|-----------|
| `UserType.PROFESIONAL` | El valor del enum se renombrara a `TERCERO` al implementar Fase A completa | Media |
| `schema.sql` constraint | El CHECK de user_type se actualizara para incluir `tercero` y excluir `profesional` | Media |
| Dashboard admin | Pantalla de generacion de invitaciones (Fase A) | Alta |
| Opcion B | Evaluar si el volumen de terceros requiere sistema de solicitudes | Baja |

---

## Alternativas de Implementacion Descartadas

- **Mantener la pantalla de seleccion con validacion manual posterior:** Genera una ventana de
  acceso no autorizado entre el registro y la revision admin. Rechazado por @Shield.
- **Flag booleano `is_professional` en vez de `user_type`:** Menos expresivo, no preparado para
  multiples roles. Rechazado por @Architect.
