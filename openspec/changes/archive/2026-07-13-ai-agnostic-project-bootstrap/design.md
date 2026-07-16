# Diseño: Plantillas B-IA para Codex con continuidad diaria

## Decisión arquitectónica

B-IA es gobernanza versionada; Gentle AI es el único router SDD. Los assets distribuibles MUST existir solo como fuentes canónicas bajo `templates/codex/`. La adopción los copia a rutas locales reconocidas del repositorio consumidor. `tests/**` y `openspec/**` son desarrollo B-IA y nunca se instalan. Ninguna operación escribe en `~/.codex/skills` ni fuera de la raíz consumidora.

```text
templates/codex/<source> → manifest.tsv → <consumer-root>/<destination>
                              ↓
                    preflight + backup + verify
```

## Autoridad y clasificación

`AGENTS.md` instalado añade idioma, gates, evidencia y persistencia; no duplica routing global. Cada ruta del plan y manifiesto porta exactamente una clase:

- `canonical-source`: asset versionado bajo `templates/codex/`.
- `consumer-destination`: ruta relativa creada o actualizada durante adopción.
- `development-only`: pruebas o artefactos internos no distribuibles.

El validador rechaza rutas sin clase, fuentes canónicas fuera de `templates/codex/`, destinos absolutos, `..`, escapes por symlink, prefijos `$HOME`/`~` y cualquier destino global. También rechaza usar una ruta instalada del propio repositorio B-IA como fuente canónica.

## Plan exacto de archivos

| Clase | Rutas |
|---|---|
| canonical-source | `templates/codex/AGENTS.md`; `templates/codex/.bia/{constitution.md,policies/**,checklists/**,validators/**,adoption/**}` |
| canonical-source | `templates/codex/.agents/skills/{bia-explorar-idea,bia-sdd-continuar,bia-iniciar-trabajo,bia-finalizar-trabajo}/SKILL.md` |
| canonical-source | `templates/codex/docs/project/**`; `templates/codex/docs/decisions/**`; `templates/codex/docs/worklog/**`; `templates/codex/.gitignore.fragment` |
| consumer-destination | `AGENTS.md`; `.bia/**`; `.agents/skills/**`; `docs/project/**`; `docs/decisions/**`; `docs/worklog/**`; entradas administradas de `.gitignore` |
| development-only | `tests/contracts/**`; `tests/fixtures/**`; `openspec/**`; archivos parciales existentes en raíz hasta la tarea de recuperación |

## Manifiesto y adopción

`templates/codex/.bia/adoption/manifest.tsv` contiene `class<TAB>source<TAB>destination<TAB>mode`; solo acepta `canonical-source` y destinos relativos. Ejemplo:

```text
canonical-source	templates/codex/AGENTS.md	AGENTS.md	merge
canonical-source	templates/codex/.agents/skills/bia-explorar-idea/SKILL.md	.agents/skills/bia-explorar-idea/SKILL.md	copy
```

`adopt.sh` resuelve ambos lados con `realpath`, prueba contención en sus raíces, ejecuta dry-run, guarda reemplazos en `.bia-backup/<timestamp>/`, copia y compara hashes. El preflight prohíbe destinos globales aunque existan.

La recuperación del apply interrumpido ocurre únicamente durante implementación: inventariar `AGENTS.md`, `.bia/**`, `.gitignore` y `tests/**` parciales; mover contenido reutilizable a su fuente canónica o desarrollo B-IA según clase; comparar antes de reemplazar; preservar desconocidos y reportarlos. No se borra nada a ciegas.

## Dispatcher y persistencia

`preflight.sh` consume `gentle-ai sdd-status ... --json --instructions`; solo `nextRecommended` autoriza fase y `blockedReasons` bloquea. Códigos: `0` válido; `2` uso; `3` dependencia desconocida; `10` política/ruta; `11` dispatcher; `12` divergencia híbrida.

La equivalencia híbrida normaliza CRLF, espacios finales y salto final, luego compara SHA-256. Engram requiere topic key exacto, único resultado activo y contenido completo. Una escritura parcial conserva `.bia/tmp/*.pending`, no actualiza estado y se repara desde la última copia OpenSpec válida.

## Registrador TDD pasivo

El apply reemplaza `tdd-evidence.sh` y la política de redacción por `templates/codex/.bia/validators/{tdd-run.sh,tdd-event.sh,tdd-self-check.sh}` y `.bia/policies/tdd-tests.tsv`. `tdd-run.sh` resuelve un `test_id` allowlisted, valida el locator antes de ejecutarlo sin argumentos y después invoca:

```text
tdd-event.sh TASK_ID PHASE TEST_ID EXIT_CODE TEST_FILE TEST_SHA256
```

El registrador nunca ejecuta procesos recibidos ni acepta argv, streams o diagnósticos. Genera UTC interno y anexa solo `timestamp_utc|task_id|phase|test_id|exit_code|test_file|test_sha256` a `.bia/evidence/tdd/events.jsonl`.

La política distribuida contiene `bia_tdd_event_self_check → .bia/validators/tdd-self-check.sh`, por lo que una adopción real puede ejecutar `tdd-run.sh adoption GREEN bia_tdd_event_self_check` y verificar el ledger inmediatamente. El self-check usa `tdd-event.sh --verify`; no copia `tests/**` de desarrollo. Cada consumidor añade después sus tests propios como pares `test_id<TAB>locator-relativo` versionados en su copia local de `tdd-tests.tsv`. El runner conserva el exit del target y reporta por separado un fallo del registrador.

`tdd-tests.tsv` mapea `test_id` a locator relativo versionado. El registrador exige campos exactos, strings no vacíos, `phase=RED|GREEN|REFACTOR`, exit code entero, id allowlisted y archivo regular contenido, propio, `nlink=1`, sin symlink. Recalcula SHA-256 y exige coincidencia. La evidencia prueba el resultado declarado por el runner y la identidad/hash del test; no prueba output forense, ejecución independiente ni cronología previa.

## Ledger y concurrencia

Antes de append valida el ledger completo: JSON por línea, schema/tipos exactos, LF final, allowlist y referencias aún resolubles. Ledger y lock deben ser regulares, propios, contenidos y sin hardlinks/symlinks. Lock serializa writers con timeout; una línea se anexa y solicita sync. No se promete atomicidad ante crash/power loss: cola truncada o corrupción fallan cerrado, se preservan para reparación explícita y no se reescriben automáticamente. Sin backfill.

Códigos: `0` registrado; `2` schema/uso; `10` path/enlace; `12` hash/ledger; `13` allowlist; `14` timeout. El runner conserva por separado el resultado del test y reporta el fallo del registro.

## Jornada y documentación

`iniciar trabajo` solo reúne y prioriza evidencia. `finalizar trabajo` produce una instantánea idempotente por `source+locator+digest`, usa `America/Mexico_City` y persiste Markdown/Engram. Decisiones de arquitectura, tecnología, seguridad, persistencia, compatibilidad o reversión costosa generan ADR; `verify/archive` bloquean documentación pendiente.

## Pruebas y reversión

`test_tdd_event.sh` cubrirá evento válido post-test; UTC interno; fases/exit/tipos; campos ausentes/extra; test_id no allowlisted; path/hash divergente; test y ledger con hardlink/symlink; LF ausente, JSON/schema corrupto; concurrencia/timeout; cero comandos/output/FD3/FIFO/Base64; no backfill. `test_adoption.sh` adoptará, ejecutará el self-check por el runner y verificará el evento real. `testing.md` documentará alcance probatorio y extensión local de la allowlist.

Rollback restaura respaldos y elimina solo destinos creados registrados; verifica que ningún path fuera del consumidor cambió. Engram no se borra: registra la reversión. Se conserva `stacked-to-main` en cuatro unidades revisables.

## No objetivos

Sin CLI B-IA, multiproveedor, ejecución automática, commits, daemon, perfiles Codex no verificados ni segundo orquestador.
