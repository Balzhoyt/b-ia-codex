# Propuesta: Plantillas B-IA para Codex con continuidad diaria

## Intención

Validar una base sin CLI donde B-IA gobierne a Gentle AI con plantillas canónicas, documentación viva y continuidad diaria sin comandos operativos.

## Alcance

### Incluido
- Fuente canónica: todos los assets distribuibles viven bajo `templates/codex/`.
- Destino consumidor: la adopción copia esos assets a rutas locales reconocidas como `AGENTS.md`, `.bia/**`, `.agents/skills/**` y `docs/**`.
- Desarrollo B-IA: `tests/**` y `openspec/**` validan la plantilla, pero no se distribuyen.
- Skills `$bia-*`, gobernanza, validadores y agentes bajo contratos Codex vigentes.
- Intenciones `iniciar trabajo` y `finalizar trabajo`, con respaldos `$bia-iniciar-trabajo` y `$bia-finalizar-trabajo`.
- Inicio basado en Git, Engram, OpenSpec y dispatcher de Gentle AI; cierre verificable con bitácora idempotente en Markdown y Engram.
- Clasificación obligatoria de cada ruta planificada y validación fail-closed de adopción, persistencia y documentación.
- Strict TDD y evidencia pasiva: un runner local ejecuta targets allowlisted y después registra resultado declarado e identidad/hash verificable del archivo, sin capturar comandos ni streams. La adopción incluye un self-check operativo; los tests del consumidor se incorporan mediante locators relativos, sin distribuir `tests/**` de B-IA.

### Excluido
- Instalaciones o escrituras globales, incluido `~/.codex/skills`.
- Assets canónicos directamente en las rutas instaladas del repositorio B-IA.
- CLI, DAG propio, comandos `/bia.*`, multiproveedor y commits automáticos.
- ADRs para decisiones triviales o fácilmente reversibles.
- Ejecución/captura de comandos, output forense y almacenes externos de logs.

## Capacidades

### Capacidades nuevas
- `codex-instruction-templates`: Plantillas Codex gobernadas, adoptables localmente y verificables.

### Capacidades modificadas
Ninguna.

## Enfoque

B-IA autoriza transiciones; Gentle AI conserva routing y estado SDD. Un manifiesto mapea cada fuente `templates/codex/...` a un destino consumidor relativo. Adopción usa preflight, dry-run, respaldo y rollback; rechaza rutas inseguras. OpenSpec documenta cambios; `docs/` el sistema; Engram el contexto. La conversación sola nunca prueba finalización. `verify` comprueba estructura, mapeo, sincronización y no-global-write. La evidencia TDD adoptada funciona desde el self-check y permite que cada consumidor declare sus propios tests en la política local.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Confundir plantilla con instalación | Clasificación y manifiesto fuente→destino obligatorios |
| Contaminar configuración global | Rechazo absoluto de destinos fuera del repositorio consumidor |
| Estado inventado o divergente | Evidencia, hashes y gates híbridos |

## Plan de reversión

Restaurar el respaldo del consumidor y eliminar solo destinos creados por manifiesto. No modificar Engram global ni borrar archivos parciales durante esta corrección de planificación.

## Dependencias

- Linux, Git, Codex, Gentle AI, OpenSpec y Engram.

## Criterios de éxito

- [ ] Toda ruta está clasificada como fuente canónica, destino consumidor o desarrollo B-IA.
- [ ] La adopción copia assets funcionales sin escribir fuera del consumidor.
- [ ] La jornada, documentación y persistencia híbrida pasan pruebas reproducibles.
- [ ] La adopción ejecuta el self-check allowlisted; el runner ejecuta targets locales y el registrador pasivo valida schema, allowlist, path/hash, ledger y concurrencia sin output, secretos ni backfill.
