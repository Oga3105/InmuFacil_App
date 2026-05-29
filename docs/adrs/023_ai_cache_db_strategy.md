# ADR 023: Estrategia de Persistencia de Resultados IA en Base de Datos

**Estado:** Aceptado
**Fecha:** 2026-05-29
**Autores:** @Architect, @Watcher, @Jules

---

## Contexto

InmuFacil utiliza Gemini AI para generar contenido contextual en seis funcionalidades distintas:
- Indice de Confort de Barrio (`comfort_service.py`)
- Guias Legales por CCAA (`ai_legal_guide_service.py`)
- Precio de Mercado (`ai_market_price_service.py`)
- Brecha de Mercado (`ai_market_gap_service.py`)
- Crecimiento Urbano (`ai_urban_growth_service.py`)
- Barrios Gemelos (`ai_neighborhood_twins_service.py`)
- Validacion de Precio de Publicacion (`ai_price_validator_service.py`)

En la version anterior, cada servicio aplicaba su propia estrategia de cache:
- **Comfort Index:** blob JSON en columna `ai_comfort_data_cache` + `ai_comfort_cache_expires_at` en la tabla `properties`.
- **Resto de servicios:** diccionario en memoria (`dict`) local al proceso uvicorn — cache perdida en cada reinicio del servidor, sin TTL real gestionado, sin persistencia entre instancias.

Esta situacion implicaba:
1. Llamadas repetidas a la API de Gemini ante cada reinicio Docker (costes variables impredecibles).
2. Patron inconsistente: una cache en columna de propiedades, otras en memoria.
3. Imposibilidad de auditar el contenido generado por IA almacenado (GDPR Art. 5.1.e — minimizacion y limitacion del plazo).
4. Sin soporte para escalar a multiples instancias del backend.

---

## Decision

Estandarizar toda la cache de resultados IA en **tablas dedicadas de PostgreSQL** con campo `expires_at` gestionado por la logica de negocio del servicio. Un modelo por tipo de consulta.

### Modelo canonico

```python
class Ai<Dominio>Cache(Base):
    __tablename__ = "ai_<dominio>_cache"
    __table_args__ = (UniqueConstraint("<clave_natural>", name="uq_<dominio>_key"),)

    id          = Column(Integer, primary_key=True, index=True)
    <clave>     = Column(String, nullable=False, index=True)   # clave de lookup
    response_json = Column(Text, nullable=False)               # JSON serializado de Gemini
    created_at  = Column(DateTime(timezone=True), server_default=func.now())
    expires_at  = Column(DateTime(timezone=True), nullable=False)
```

### Tablas creadas (migration en `alembic/`)

| Tabla | Clave Natural | TTL | Justificacion |
|---|---|---|---|
| `ai_comfort_index_cache` | `property_id` | 24 h | Dato por inmueble, cambia si el barrio evoluciona |
| `ai_legal_guide_cache` | `ccaa` + `guide_type` | 30 dias | Normativa cambia lentamente |
| `ai_market_price_cache` | `postal_code` + `property_type` | 7 dias | Precios de mercado, volatilidad media |
| `ai_market_gap_cache` | `postal_code` | 7 dias | Idem |
| `ai_urban_growth_cache` | `postal_code` | 30 dias | Tendencia de largo plazo |
| `ai_neighborhood_twins_cache` | `cache_key` (hash) | 30 dias | Barrios similares, muy estable |
| `ai_price_validation_cache` | `cache_key` (hash) | 24 h | Validacion relativa al precio actual del inmueble |

### Patron de acceso en servicio

```python
cached = db.query(AiXxxCache).filter(
    AiXxxCache.clave == valor,
    AiXxxCache.expires_at > datetime.utcnow()
).first()
if cached:
    return json.loads(cached.response_json)

result = await gemini_call(...)
db.merge(AiXxxCache(clave=valor, response_json=json.dumps(result),
                    expires_at=datetime.utcnow() + timedelta(days=TTL)))
db.commit()
return result
```

---

## Opciones Consideradas

### Opcion A: Tablas dedicadas por dominio en PostgreSQL (ELEGIDA)

- **Pros:** Persistencia entre reinicios. Cache compartida entre instancias. TTL explicitp y auditable. Patron homogeneo. Purga automatizable via cron o pg_partman.
- **Contras:** Incremento del esquema (7 tablas extra). Latencia de escritura en primera consulta. Necesidad de migracion Alembic.

### Opcion B: Redis / Memcached

- Requiere nuevo componente en infraestructura Docker. Coste operativo adicional. No alineado con la estrategia de simplicidad de stack (PostgreSQL como unico almacen).
- Rechazada: no justificada dado el volumen actual de consultas.

### Opcion C: Cache en memoria del proceso (estado anterior)

- Se pierde en cada reinicio. No escala. No auditable.
- Rechazada por las razones del contexto.

### Opcion D: Columna blob en tabla `properties` (estado anterior comfort index)

- Acopla datos de IA a la entidad de negocio. Dificulta la purga por TTL.
- Rechazada: migrado a tabla propia en esta decision.

---

## Consecuencias

### Positivas

- Coste de API Gemini predecible y reducido (no se repite la misma llamada hasta que expira el TTL).
- Patron replicable para cualquier nuevo servicio IA: crear tabla + seguir el patron canonico.
- Auditabilidad GDPR: el contenido generado por IA es identificable, acotado en el tiempo y purgable.
- Resiliencia ante reinicios Docker (ciclos de deploy frecuentes en VPS).

### Negativas

- Schema mas grande (+7 tablas). Aceptable dado que todas tienen estructura minima.
- Deuda tecnica potencial: el TTL se calcula en Python, no en PostgreSQL. Si se necesita purga automatica, anadir un cron job o pg_cron en el futuro.

---

## Deuda Tecnica

| Item | Descripcion | Prioridad |
|---|---|---|
| Purga de registros expirados | Cron job `DELETE FROM ai_*_cache WHERE expires_at < NOW()` | Media |
| `ai_comfort_data_cache` en `properties` | Columna legacy todavia presente — deprecar y eliminar tras confirmar que no hay lectores | Baja |
| TTL configurable via `.env` | Actualmente hardcodeado en cada servicio | Baja |

---

## Archivos Relacionados

- `backend/src/models/ai_cache.py` — Modelos SQLAlchemy
- `backend/src/services/comfort_service.py` — Primer consumidor migrado
- `backend/src/services/ai_legal_guide_service.py`
- `backend/src/services/ai_market_price_service.py`
- `backend/src/services/ai_market_gap_service.py`
- `backend/src/services/ai_urban_growth_service.py`
- `backend/src/services/ai_neighborhood_twins_service.py`
- `backend/src/services/ai_price_validator_service.py`
