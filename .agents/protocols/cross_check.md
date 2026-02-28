# 🔄 Protocolo: "Check Cruzado Continuo"

## Trigger
Después de cada acción significativa (refactor, cleanup, feature).

## Acción
El sistema debe evaluar automáticamente si la acción completada dispara responsabilidades en otros agentes.

## Ejemplo
*   Si @Architect mueve archivos -> @DevOps debe verificar Commits.
*   Si @Jules crea código -> @Shield debe auditar seguridad.

## Objetivo
Evitar silos y asegurar la integridad del ciclo de vida (Git, Docs, Tests).
