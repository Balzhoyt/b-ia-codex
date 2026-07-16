# Tareas: Plantillas B-IA para Codex

## Review Workload Forecast

| Campo | Valor |
|---|---|
| Líneas estimadas | 1,280–1,780; incremento 4.4: 180–280 |
| Riesgo de 400 líneas | High |
| PRs encadenadas | Yes |
| División | PR 1 → PR 2 → PR 3 → PR 4 |
| Estrategia | ask-on-risk; stacked-to-main |
| Workload decision | resolved |

Decision needed before apply: No  
Chained PRs recommended: Yes  
400-line budget risk: High  
Chain strategy: stacked-to-main

Rutas `templates/codex/**`: `canonical-source`; destinos de fixtures: `consumer-destination`; `tests/**` y `openspec/**`: `development-only`. Las 15 tareas están completas y requieren una nueva verificación.

## PR 1: Recuperación, harness y gobernanza

- [x] 1.1 Única excepción de bootstrap: RED en `tests/contracts/test_harness.sh`; inventariar el apply interrumpido (`AGENTS.md`, `.bia/**`, `.gitignore`, `tests/**`), clasificarlo y mover contenido reutilizable sin borrar desconocidos; GREEN en `tests/contracts/run.sh`; inmediatamente fijar `openspec/config.yaml` con `rules.apply.tdd: true` y `test_command: bash tests/contracts/run.sh`; REFACTOR con runner. PR 2–4 MUST NOT comenzar antes de este gate.
- [x] 1.2 RED en `tests/contracts/test_governance.sh`; GREEN en `templates/codex/AGENTS.md`, `templates/codex/.bia/{constitution.md,policies/{sdd,documentation,daily-work}.md,checklists/{exploration,artifact,archive}.md}`; validar que no existan fuentes canónicas en rutas instaladas.
- [x] 1.3 Crear fixtures `tests/fixtures/{dispatcher,artifacts,engram,worklog,consumer}/` con casos válidos, globales, no clasificados, symlink y escape.

## PR 2: Rutas, contratos y persistencia

- [x] 2.1 RED en `tests/contracts/test_paths.sh`; GREEN en `templates/codex/.bia/validators/{common,paths,preflight}.sh` para clases, contención y rechazo de `~/.codex/skills`, absolutos y `..`.
- [x] 2.2 RED en `tests/contracts/test_artifact.sh`; GREEN en `templates/codex/.bia/validators/artifact.sh`; comprobar idioma, secciones y referencias.
- [x] 2.3 RED en `tests/contracts/test_hybrid.sh`; GREEN en `templates/codex/.bia/validators/{hybrid.sh,lib/canonicalize.sh}` para unicidad Engram, SHA-256, `.pending` y recuperación parcial.
- [x] 2.4 RED en `tests/contracts/test_docs.sh`; GREEN en `templates/codex/.bia/validators/docs.sh` para ADR, enlaces y pendientes.
- [x] 2.5 RED en `tests/contracts/test_skills.sh`; GREEN en `templates/codex/.agents/skills/{bia-explorar-idea,bia-sdd-continuar}/SKILL.md`; verificar copia exacta a `.agents/skills/**` del consumidor.

## PR 3: Continuidad y documentación

- [x] 3.1 RED en `tests/contracts/test_worklog.sh`; GREEN en `templates/codex/.bia/validators/{worklog.sh,lib/evidence.sh}` para fuentes parciales, prioridad, zona horaria e idempotencia.
- [x] 3.2 RED en el mismo test; GREEN en `templates/codex/.agents/skills/{bia-iniciar-trabajo,bia-finalizar-trabajo}/SKILL.md`; comprobar destinos locales, evidencia y ausencia de commits.
- [x] 3.3 RED en `tests/contracts/test_docs.sh`; GREEN en `templates/codex/docs/{project/{overview,architecture,development,testing}.md,decisions/{README,ADR-template}.md,worklog/{README,templates/day.md}}`.

## PR 4: Adopción y cierre

- [x] 4.1 RED en `tests/contracts/test_adoption.sh`; GREEN en `templates/codex/.bia/adoption/{adopt.sh,rollback.sh,manifest.tsv}` para dry-run, respaldo, fuente→destino, rollback y no-global-write.
- [x] 4.2 RED en adopción; GREEN en `templates/codex/.gitignore.fragment`; adoptar en consumidor temporal, comparar hashes y verificar que la configuración Strict TDD activada en 1.1 permanece vigente.
- [x] 4.3 Ejecutar `bash tests/contracts/run.sh`; validar clasificación total, copias consumidoras, OpenSpec–Engram, rollback, documentación, idioma y ausencia de escrituras globales, CLI o multiproveedor.
- [x] 4.4 RED en `tests/contracts/test_tdd_event.sh`; GREEN en `templates/codex/.bia/validators/tdd-event.sh`, `.bia/policies/tdd-tests.tsv`, runner, manifiesto y `testing.md`; eliminar wrapper/redacción supersedidos; REFACTOR y suite. Registrar pasivamente task/fase/test_id/exit/test_file/hash con UTC interno; validar schema/tipos/allowlist/path/hash/LF/ledger. Probar positivos, campos extra/ausentes, fases/exit inválidos, hash divergente, hardlink/symlink test/ledger, corrupción, concurrencia/timeout, cero ejecución/argv/output/diagnóstico/FD3/FIFO/Base64 y no backfill. Presupuesto: 180–280 líneas, riesgo Medium.
