# Gobernanza B-IA

B-IA define políticas y gates del repositorio. Gentle AI es el único router y orquestador SDD; B-IA no replica su DAG, estado ni delegación.

## Reglas obligatorias

- Los artefactos técnicos se escriben en español profesional y conservan identificadores técnicos.
- OpenSpec es la fuente versionada; Engram conserva la copia de recuperación en modo híbrido.
- Solo `nextRecommended` del dispatcher autoriza la siguiente fase y cualquier bloqueo detiene el flujo.
- Las skills `$bia-*` validan antes y después de delegar en la skill oficial de Gentle AI.
- No se declara trabajo terminado sin evidencia verificable ni se crean commits automáticamente.
- Las decisiones permanentes significativas deben llegar a `docs/decisions/` y la documentación vigente a `docs/project/`.

## Intenciones diarias

`iniciar trabajo` equivale a `$bia-iniciar-trabajo`; refresca evidencia y prioridades sin ejecutar tareas. `finalizar trabajo` equivale a `$bia-finalizar-trabajo`; genera una bitácora verificable e idempotente.

Todo gate de aceptación falla de forma cerrada. B-IA puede endurecer, nunca debilitar, un bloqueo de Gentle AI.
