# Progreso de implementación

## TDD Cycle Evidence

La tabla registra únicamente comandos y resultados realmente ejecutados durante apply y remediación. **Limitación de evidencia**: no se conservaron logs crudos con timestamp por ciclo; por eso no se atribuyen baselines numéricos que no puedan probarse. Para archivos nuevos, `Safety net` indica que no existía producción previa; la regresión acumulada comprobable es la suite completa ejecutada tras cada unidad.

| Tarea | Archivo de prueba | Capa | Safety net | RED observado | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|---|---|
| 1.1 | `test_harness.sh` | contrato | Bootstrap, sin producción previa | exit 1 sin runner/configuración | runner prueba suites PASS y propaga exit 7 | caso PASS + caso FAIL | suite completa PASS |
| 1.2 | `test_governance.sh` | contrato | fuentes nuevas; suite de harness | exit 1 sin clasificación canónica | gobernanza canónica verificada | presencia + prohibiciones | suite completa PASS |
| 1.3 | `test_governance.sh` | contrato | fixtures nuevos | exit 1 por fixture ausente | fixtures requeridos presentes | válido + global + escape + symlink | suite completa PASS |
| 2.1 | `test_paths.sh` | contrato | suite unidad 1 PASS | exit 1 sin validador | rutas locales aceptadas | absolutos, `..`, global, clase y symlink rechazados | suite completa PASS |
| 2.2 | `test_artifact.sh` | contrato | suite previa PASS | exit 1 sin validador | artefacto válido aceptado | título ausente y enlace roto rechazados | suite completa PASS |
| 2.3 | `test_hybrid.sh` | contrato | suite previa PASS | exit 1 sin contrato híbrido | contenido/topic exactos aceptados | duplicado, topic incorrecto y contenido alterado rechazados | suite completa PASS |
| 2.4 | `test_docs.sh` | contrato | suite previa PASS | exit 1 sin validador | docs y ADR válidos aceptados | pendiente y decisión solo Engram rechazados | suite completa PASS |
| 2.5 | `test_skills.sh` | contrato | suite previa PASS | exit 1 sin skills | fuentes copiadas exactamente | dos workflows y prohibiciones | suite completa PASS |
| 3.1 | `test_worklog.sh` | contrato | suite unidad 2 PASS | exit 1 sin renderer | evidencia completa renderizada | digest vacío rechazado y duplicado deduplicado | suite completa PASS |
| 3.2 | `test_worklog.sh` | contrato | renderer validado | exit 1 sin skills diarias | ambas skills encontradas | inicio + cierre, sin commits | suite completa PASS |
| 3.3 | `test_docs.sh` | contrato | validador docs PASS | exit 1 sin fuentes durables | ocho fuentes aceptadas | docs + ADR + worklog | suite completa PASS |
| 4.1 | `test_adoption.sh` | integración local | suite unidad 3 PASS | exit 1 sin adopción | adopción y rollback en Git temporal | dry-run, escape, manifiesto incompleto/extra y directorios | suite completa PASS |
| 4.2 | `test_adoption.sh` | integración local | adopción base validada | exit 1 sin fragmento/config comprobable | fragmento y Strict TDD preservados | reemplazo + creación local | suite completa PASS |
| 4.3 | `run.sh` y checks finales | aceptación | 13 tareas verdes | checks integrales previos al cierre | `PASS: 10 contract test files` | inventario, prohibiciones, híbrido y rollback | suite final PASS |
| 4.4 | `test_tdd_event.sh` | contrato/integración local | `test_tdd_evidence.sh` PASS y suite acumulada `PASS: 12 contract test files` | test nuevo → exit 1 porque registrador/política no existían | registrador pasivo → exit 0 | positivo; schema/campos/tipos; allowlist/path/hash y locator duplicado; enlaces; LF/corrupción; 8 writers; timeout; runner y fallo independiente; no backfill | `bash -n` y test focal PASS; suite `PASS: 12 contract test files` |

## Unidad 1 — Harness y gobernanza

Estado: completada.

| Tarea | RED | GREEN | REFACTOR |
|---|---|---|---|
| 1.1 | `bash tests/contracts/test_harness.sh` → exit 1 | runner creado y configuración TDD activada | `bash tests/contracts/run.sh` → 2 archivos PASS |
| 1.2 | `bash tests/contracts/test_governance.sh` → exit 1 | fuentes canónicas bajo `templates/codex/` | suite completa PASS |
| 1.3 | fixture requerida ausente → exit 1 | fixtures clasificados creados | suite completa PASS |

## Unidad 2 — Rutas, contratos y persistencia

Estado: completada; suite: 7 archivos PASS.

| Tarea | RED | GREEN | REFACTOR |
|---|---|---|---|
| 2.1 | `test_paths.sh` → exit 1 | clases, contención, dispatcher y códigos implementados | suite PASS |
| 2.2 | `test_artifact.sh` → exit 1 | idioma, secciones y referencias validadas | suite PASS |
| 2.3 | `test_hybrid.sh` → exit 1 | canonicalización, SHA-256, unicidad y recuperación | suite PASS |
| 2.4 | `test_docs.sh` → exit 1 | enlaces, ADR y pendientes fail-closed | suite PASS |
| 2.5 | `test_skills.sh` → exit 1 | wrappers oficiales sin DAG paralelo | suite PASS |

## Unidad 3 — Continuidad y documentación

Estado: completada; suite: 8 archivos PASS.

| Tarea | RED | GREEN | REFACTOR |
|---|---|---|---|
| 3.1 | `test_worklog.sh` → exit 1 | evidencia, prioridad, zona e idempotencia | suite PASS |
| 3.2 | mismo contrato inicialmente RED | skills de inicio/cierre y persistencia local/híbrida | suite PASS |
| 3.3 | `test_docs.sh` con fuentes durables → exit 1 | documentación viva y plantilla ADR/bitácora | suite PASS |

## Unidad 4 — Adopción y cierre

Estado: completada; suite: 9 archivos PASS; validación integral: `FINAL_VALIDATION_PASS`.

| Tarea | RED | GREEN | REFACTOR |
|---|---|---|---|
| 4.1 | `test_adoption.sh` → exit 1 | dry-run, respaldo, manifiesto y rollback seguros | suite PASS |
| 4.2 | mismo contrato inicialmente RED | fragmento gestionado y Strict TDD preservado | suite PASS |
| 4.3 | validación integral de clasificación y copias | todos los contratos y prohibiciones satisfechos | suite final PASS |

## Resultado acumulado

Hay 15/15 tareas completas. Base64 y el wrapper hash-only de 4.4 permanecen como evidencia histórica supersedida; el contrato vigente usa únicamente el registrador pasivo. No se crearon commits, ramas, pushes ni PRs. Siguiente recomendación: `sdd-verify`.

## Remediación posterior a revisión

- El runner ahora demuestra conducta productiva: ejecuta un directorio de contratos inyectado, informa PASS y propaga el código `7` de una prueba fallida.
- La validación híbrida exige resultado activo único, `topic_key` exacto y contenido completo canónicamente equivalente; topic incorrecto y contenido alterado devuelven `12`.
- La adopción compara el manifiesto con todo el inventario canónico y rechaza fuentes faltantes, extra o duplicadas; rollback elimina solo directorios que la adopción registró como creados.
- La bitácora rechaza identidades incompletas y deduplica por `source+locator+digest`.
- La validación documental detecta decisiones significativas que permanecen únicamente en Engram sin referencia durable.
- Comando final: `bash tests/contracts/run.sh` → `PASS: 10 contract test files`.

## Remediación final de objetos y campos asociados

Evidencia RED real antes de producción:

| Contrato | RED | GREEN | Triangulación y refactor |
|---|---|---|---|
| Objeto Engram activo | `bash tests/contracts/test_hybrid.sh` → exit 1 con valores esperados tomados de un objeto `inactive` | exit 0 usando selección estructural del único objeto activo | duplicado, topic incorrecto, contenido alterado y objetos mezclados rechazados |
| Evidencia diaria completa | `bash tests/contracts/test_worklog.sh` → exit 1 al aceptar `summary`/`observed_at` ausentes y status desconocido | exit 0 validando seis campos y enum | negativos individuales para los seis campos, status desconocido y dedupe por identidad |
| Destino único de adopción | `bash tests/contracts/test_adoption.sh` → exit 1 al aceptar dos fuentes hacia el mismo destino | exit 0 rechazando destinos duplicados | convive con inventario incompleto, extra y fuente duplicada |
| Referencia durable | `bash tests/contracts/test_docs.sh` → exit 1 al aceptar `durable_ref` omitido | exit 0 exigiendo string no vacío y archivo resoluble bajo `docs/` | omitido, vacío, tipo inválido y referencia inexistente rechazados; referencia válida aceptada |

Safety net: `bash tests/contracts/run.sh` pasaba antes de cada remediación, pero no cubría estos casos; tras RED→GREEN y refactor, la ejecución final devolvió `PASS: 10 contract test files`.

## Remediación del gate estructurado del dispatcher

Se conservó sin cambios el `verify-report.md` con veredicto FAIL para que la siguiente fase `sdd-verify` lo sustituya con evidencia nueva.

| Archivo de prueba | Capa | Safety net | RED real | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|---|
| `tests/contracts/test_preflight.sh` | contrato de routing | suite previa `PASS: 10 contract test files`, sin cobertura JSON adversarial | exit 1: JSON truncado y valores anidados podían autorizar `spec` | exit 0 con parseo completo mediante dependencia explícita `jq` y lectura top-level | truncado, trailing garbage, blockers reales con autorización anidada, campos ausentes/null/tipos inválidos, item de blocker no string y coincidencia no exacta | `test_paths.sh` continuó PASS y suite completa devolvió `PASS: 11 contract test files` |

El preflight devuelve `3` si `jq` no está disponible, `11` ante JSON inválido/contrato top-level inválido/bloqueo/fase distinta y `0` solo cuando `blockedReasons` es un array vacío de strings y `nextRecommended` es el string top-level exacto esperado.

## Remediación de integración de dependencias

| Contratos | Safety net | RED real | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|
| `test_preflight.sh`, `test_adoption.sh` | suite previa `PASS: 11 contract test files` sin simular ausencia de dependencias | ambos devolvieron exit 1: una fixture sin `jq` no bloqueaba preflight/adopción y la documentación no lo declaraba | ambos devolvieron exit 0 tras centralizar el contrato en `validators/lib/dependencies.sh` | fixture completa acepta; fixture sin `jq` devuelve `3`; adopción real continúa funcionando | manifiesto regenerado con cobertura exacta del nuevo archivo canónico y suite completa `PASS: 11 contract test files` |

El requisito de consumidor se documenta una sola vez en `docs/project/development.md`: `git`, `codex`, `gentle-ai`, `engram` y `jq`. Preflight y adopción consumen la misma función.

## Remediación del límite de confianza de dependencias

| Contratos | Safety net | RED real | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|
| `test_preflight.sh`, `test_adoption.sh` | suite previa `PASS: 11 contract test files` | ambos devolvieron exit 1 porque una variable controlada por caller podía sustituir el resultado real de `command -v` | ambos devolvieron exit 0 tras eliminar toda rama productiva de override | PATH autocontenido completo; ausencia individual de `jq`, `codex`, `gentle-ai`, `engram` y `git`; variable antigua definida pero ignorada | helper de pruebas `tests/contracts/lib/path_fixture.sh`, verificación de dependencias antes de usar Git y suite completa `PASS: 11 contract test files` |

El código distribuido verifica siempre mediante `command -v`; no contiene flags, variables ni fixtures que permitan sustituir el resultado. Las únicas menciones de la variable antigua permanecen en regresiones de desarrollo que prueban que ya no tiene efecto.

## Unidad 4.4 — Implementación reversible supersedida (FAIL histórico)

Esta sección preserva lo ejecutado sin atribuirlo al contrato vigente. La solución Base64 alcanzó GREEN local y luego falló revisión de seguridad; no completa 4.4.

| Archivo de prueba | Capa | Safety net | RED real | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|---|
| `tests/contracts/test_tdd_evidence.sh` | contrato/integración local | `bash tests/contracts/run.sh` → `PASS: 11 contract test files` antes del cambio | exit 1 porque no existían registrador, política ni documentación | exit 0 con streams separados sanitizados, Base64 reversible, hash revalidado y evento posterior | modo inactivo; exit/streams; timestamp UTC por PATH de test; metadata; append; overwrite; hash divergente; artefacto ausente; lock; symlink; comando sensible; no backfill; fallo entre artefacto y evento | `bash -n` PASS, adopción/docs PASS y suite final `PASS: 12 contract test files` |

Estas afirmaciones describen únicamente la implementación reversible supersedida. El `verify-report.md` continúa STALE y no autoriza archivo.

## Remediación de seguridad de evidencia TDD

| Hallazgo | Safety net | RED real | GREEN ejecutado | Triangulación y refactor |
|---|---|---|---|---|
| Escape por hardlink | `test_tdd_evidence.sh` previo PASS, sin enlaces múltiples | exit 1: verificación aceptaba artefactos con hardlink y el append podía alcanzar un ledger enlazado externamente | archivos existentes exigen tipo regular, propietario actual y `nlink=1`; publicación y append atómico revalidan bajo lock | ledger externo permanece byte a byte intacto; artefacto con hardlink devuelve `12`; symlinks continúan rechazados |
| Cobertura de secretos | política v1 previa cubría solo `KEY=value` en streams | exit 1: metadata contó 1 de 6 y el evento conservó `--token command-secret` | filtro único case-insensitive sanitiza comando, stdout y stderr antes de persistir | JSON, espacios, `Authorization: Bearer`, campo con `:`, `API_KEY=` y flag; Base64 decodificado y evento no contienen originales; texto inocuo se conserva |
| Recuperación de lock | lock exclusivo previo sin identidad | exit 1: un lock muerto bloqueaba indefinidamente | `owner.pid` regular/propio/sin hardlinks; PID vivo nunca se roba y PID muerto bien formado se aísla antes de recrear | lock vivo y metadata malformada devuelven `12`; lock muerto se recupera y limpia determinísticamente |

Ejecuciones históricas: `test_tdd_evidence.sh` → exit 0 y suite → `PASS: 12 contract test files`. Esos GREEN validan el contrato Base64 anterior, no la tarea hash-only vigente.

## Remediación 4.4 wrapper hash-only — supersedida (FAIL de diseño)

Esta implementación ejecutaba comandos y coordinaba streams/FIFOs/FD3. Sus pruebas se preservan como historia, pero el rediseño final eliminó por completo esa responsabilidad; no completa 4.4.

| Archivo de prueba | Capa | Safety net | RED real | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|---|
| `tests/contracts/test_tdd_evidence.sh` | contrato/integración local | la prueba hash-only previa pasaba antes de los cuatro repros críticos | exit 1: `diagnostic_status` era null y `command_sanitized` aún conservaba valores; los repros adicionales exigieron LF final y 12 writers exitosos | exit 0 con dos handlers esperados, SHA-256/tamaños separados, argv omitido, diagnóstico constante y evento solo tras resultados válidos | binario/NUL/chunks; tamaño >4096; hasher/sizer/jq/mv/sync fallidos; hasher lento; FD3; symlink/hardlink; 12 concurrentes; timeout PID vivo; JSONL sin LF/truncado y rotación; reloj, modo inactivo y no backfill | `bash -n` PASS; prueba focal PASS; `bash tests/contracts/run.sh` → `PASS: 12 contract test files` |

La captura reemite los streams originales y conserva el exit code del comando. Solo persiste sus hashes y tamaños; los FIFOs no contienen archivos regulares con output y los temporales guardan exclusivamente digest, contadores y staging del ledger. `bia-redaction-v2` omite SIEMPRE el diagnóstico textual: persiste únicamente `diagnostic_status: omitted_security_policy`, tamaños y truncación derivada.

`command_sanitized` no conserva argumentos: usa basename allowlisted, `arg_count` y `[ARGS_OMITTED]`. Los fallos internos comprobados producen `capture_status=failed` por FD 3, no publican evento y no sustituyen el exit code del comando. El ledger se revalida como regular, propio y `nlink=1`; `verify` rechaza explícitamente una última línea sin LF. Una generación truncada se mueve intacta a `events.recovery.*` y el evento nuevo referencia ruta/hash.

El lock usa espera/backoff acotado: 12 capturas simultáneas terminaron exitosas y produjeron 12 eventos JSON válidos. Un PID vivo no se roba; al agotar el timeout se informa por FD 3 sin alterar streams/exit. Lock, staging, rename y sync ordenan writers vivos y permiten rollback observado, pero no prometen atomicidad ante crash o pérdida de energía.

La política v1 y las referencias Base64 distribuibles se eliminaron; manifiesto, adopción y documentación apuntan a v2. `verify-report.md` permanece STALE hasta una nueva fase `sdd-verify`.

Desviación deliberada del diseño anterior: no existe sanitizer textual ni sus regex. La instrucción correctiva reemplazó ese componente por omisión constante, por lo que su fallo es imposible por construcción; los fallos del contador de tamaño cubren el segundo handler auxiliar.

## Remediación 4.4 registrador pasivo — COMPLETADA

| Archivo de prueba | Capa | Safety net | RED real | GREEN ejecutado | Triangulación | REFACTOR |
|---|---|---|---|---|---|---|
| `tests/contracts/test_tdd_event.sh` | contrato/integración local | `bash tests/contracts/test_tdd_evidence.sh` → exit 0; rerun de `bash tests/contracts/run.sh` → `PASS: 12 contract test files` | `bash tests/contracts/test_tdd_event.sh` → exit 1 antes de crear registrador y política | exit 0 con evento pasivo, UTC interna, allowlist y hash recalculado | campos ausentes/extra, timestamp y entero inválidos, fase, id/path/hash y locator duplicado, test y ledger enlazados, LF/corrupción, 8 writers, timeout vivo, verify vacío, runner con exit 7 y fallo de registro separado | `bash -n` PASS; test focal PASS; suite final `PASS: 12 contract test files` |

El runner ejecuta primero y registra después únicamente cuando recibe `BIA_TDD_TASK_ID` y `BIA_TDD_PHASE`. Conserva el exit del test en el evento y, si el registro falla, informa por separado `test_exit` y `registrar_exit`. El registrador acepta exactamente seis campos, no ejecuta el test ni recibe comandos, argv, streams, diagnóstico, FIFO, FD3, raw o Base64. El evento contiene solo timestamp UTC, tarea, fase, test id, exit code declarado, locator y SHA-256.

La política versionada vincula cada `test_id` con un locator relativo. Registro y verify exigen archivos regulares propios con `nlink=1`, contención bajo el consumidor, hash actual, schema/tipos exactos, entero 0–255, UTC válida y LF final. Ledger corrupto o enlazado falla cerrado; writers concurrentes esperan el lock y un lock vivo agota el timeout sin append. No hay recuperación automática ni backfill y no se promete atomicidad frente a crash o pérdida de energía.

Se eliminaron `tdd-evidence.sh`, `tdd-redaction-v2.md` y su contrato de captura. Manifiesto, dependencias y documentación distribuidos ahora apuntan exclusivamente a `tdd-event.sh` y `tdd-tests.tsv`.

## Rerun correctivo del gate automático — integración adoptada

La evidencia inferior describe comandos observados durante este rerun. No se conservaron logs RED independientes: OpenSpec registra resultados y códigos vistos en la sesión, con la misma limitación de procedencia declarada al inicio del artefacto.

| Contrato | Safety net | RED observado | GREEN ejecutado | Triangulación y REFACTOR |
|---|---|---|---|---|
| Adopción operativa de evidencia | `test_adoption.sh`, `test_apply_progress.sh` y suite completa pasaban antes de la corrección | `bash tests/contracts/test_adoption.sh` → exit 1: el consumidor no tenía runner/self-check operativo; `bash tests/contracts/test_apply_progress.sh` → exit 1: estado aún 14/15 | ambos → exit 0 tras adoptar `tdd-run.sh`, self-check allowlisted y estado 15/15/verify-next | consumidor adoptado ejecuta `tdd-run.sh adoption GREEN bia_tdd_event_self_check`, verifica evento/hash y luego `tdd-event.sh --verify`; no copia `tests/**` de B-IA |

El target distribuido `.bia/validators/tdd-self-check.sh` verifica el ledger y está allowlisted en `tdd-tests.tsv`. `tdd-run.sh` valida política, contención, propietario, `nlink=1` y hash antes de ejecutar un target sin argumentos; después delega exclusivamente el registro a `tdd-event.sh`. Los tests propios del consumidor se integran mediante pares versionados `test_id<TAB>locator-relativo`, no mediante copia de los contratos de desarrollo.

El `state.yaml` ahora contiene 15 tareas completas, `pending: []` y `next_recommended: verify`. `test_apply_progress.sh` exige explícitamente la fila 4.4 y esos tres invariantes de estado.
