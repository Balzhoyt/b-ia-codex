# Pruebas

Registre capas, comandos y límites de verificación del consumidor. El conjunto B-IA usa:

```bash
bash tests/contracts/run.sh
```

Cada cambio de producción sigue RED–GREEN–REFACTOR cuando existe un runner ejecutable.

## Evidencia TDD pasiva

La adopción instala un self-check allowlisted que prueba la integración sin copiar los contratos `tests/**` de B-IA:

```bash
.bia/validators/tdd-run.sh adoption GREEN bia_tdd_event_self_check
.bia/validators/tdd-event.sh --verify
```

Para integrar un test propio, agregue una línea versionada y única a `.bia/policies/tdd-tests.tsv` con formato `test_id<TAB>locator-relativo`, marque el archivo como ejecutable y llame `.bia/validators/tdd-run.sh TASK_ID PHASE TEST_ID`. El runner no acepta argumentos adicionales para el target: si necesita fixtures, configúrelas dentro del test reproducible.

El registrador recibe exactamente `task_id`, `phase`, `test_id`, `exit_code`, `test_file` y el SHA-256 calculado por el runner. Genera el timestamp UTC internamente, comprueba que el identificador y locator coincidan con `.bia/policies/tdd-tests.tsv`, exige un archivo regular propio sin symlink ni hardlink y recalcula el hash antes de anexar el evento.

El evento contiene únicamente `timestamp_utc|task_id|phase|test_id|exit_code|test_file|test_sha256`. Prueba el resultado declarado y la identidad/hash actual del archivo de prueba; NO demuestra output forense, ejecución independiente ni cronología previa. El registrador no ejecuta tests, no recibe comandos ni captura streams o diagnóstico.

El ledger `.bia/evidence/tdd/events.jsonl` exige LF final, JSON válido, schema y tipos exactos, UTC válida, allowlist vigente y coherencia actual de locator/hash. Ledger y tests enlazados se rechazan. Los writers se serializan con lock y timeout; append y sync no prometen atomicidad ante crash o pérdida de energía.

La verificación es read-only y nunca sintetiza eventos ausentes:

```bash
.bia/validators/tdd-event.sh --verify
```

El runner conserva el exit code del target y un fallo del registrador se reporta por separado, pero hace fallar el workflow para evitar atribuir evidencia inexistente. No existe backfill.
