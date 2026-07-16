# Especificación de plantillas B-IA para Codex

## Propósito

Plantillas Codex.

## Requisitos

### Requirement: Rutas clasificadas

Cada ruta MUST usar `canonical-source|consumer-destination|development-only`; fuentes MUST vivir en `templates/codex/` y destinos ser locales.

#### Scenario: Mapeo válido
- GIVEN `templates/codex/.agents/skills/bia-explorar-idea/SKILL.md`
- WHEN el manifiesto la adopta
- THEN MUST copiarla a `.agents/skills/bia-explorar-idea/SKILL.md` dentro del consumidor

#### Scenario: Ruta insegura
- GIVEN una ruta no clasificada, global o fuente externa a `templates/codex/`
- WHEN se valida
- THEN MUST rechazarse antes de escribir

### Requirement: Gobernanza

B-IA MUST gobernar; Gentle AI MUST enrutar; `/bia.*` MUST fallar.

#### Scenario: Intención equivalente
- GIVEN una intención diaria o su `$bia-*`
- WHEN se interpreta
- THEN MUST delegar el mismo workflow gobernado

### Requirement: Documentación viva

OpenSpec MUST guardar cambios; `docs/` estado; Engram contexto; ADR decisiones significativas.

#### Scenario: Decisión solo en memoria
- GIVEN una decisión permanente solo en Engram
- WHEN se verifica
- THEN MUST marcarse documentación versionada pendiente

### Requirement: Documentación planificada

`tasks.md` MUST planificar documentación verificable.

#### Scenario: Diseño con impacto
- GIVEN un cambio arquitectónico
- WHEN se planifica
- THEN MUST incluir destino `docs/` y ADR aplicable

### Requirement: Inicio

B-IA MUST priorizar evidencia sin ejecutar.

#### Scenario: Evidencia parcial
- GIVEN una fuente inaccesible
- WHEN inicia la jornada
- THEN MUST declararla y MUST NOT inventar estado

#### Scenario: Inicio repetido
- GIVEN una jornada iniciada
- WHEN se repite
- THEN MUST refrescar sin duplicar ni ejecutar

### Requirement: Cierre verificable

B-IA MUST exigir evidencia; MUST NOT aceptar conversación ni crear commits.

#### Scenario: Afirmación sin evidencia
- GIVEN una tarea solo conversada
- WHEN finaliza la jornada
- THEN MUST NOT registrarla como completada

### Requirement: Bitácora idempotente

El cierre MUST sincronizar Markdown y Engram idempotentemente.

#### Scenario: Cierre repetido
- GIVEN una bitácora existente
- WHEN se vuelve a finalizar
- THEN MUST actualizarla sin duplicar evidencia

### Requirement: Adopción segura

Adopción MUST respaldar desde manifiesto; rollback MUST ser selectivo.

#### Scenario: Escape del consumidor
- GIVEN un destino fuera de la raíz consumidora
- WHEN se valida adopción o rollback
- THEN MUST fallar sin escribir ni borrar

### Requirement: Strict TDD

Tras bootstrap, implementación MUST seguir RED–GREEN–REFACTOR con el runner.

#### Scenario: Runner habilitado
- GIVEN la tarea 1.1 en GREEN
- WHEN continúa la implementación
- THEN MUST activar TDD y ejecutar cada ciclo

### Requirement: Evidencia prospectiva

Registrador MUST ser pasivo: MUST NOT ejecutar ni recibir/persistir `argv|stdout|stderr|diagnóstico|raw|Base64`. Un runner local MUST ejecutar un target allowlisted sin argumentos y, tras el test, enviar `task_id|phase|test_id|exit_code|test_file|test_sha256`; UTC MUST generarse internamente. La adopción MUST incluir un self-check allowlisted ejecutable sin copiar `tests/**` de desarrollo. Consumidor MAY añadir locators relativos de sus propios tests a la política local. Antes de append MUST validar schema/tipos, fase, allowlist, contención y hash recalculado. Evento prueba resultado declarado e identidad/hash, no output ni historia. MUST NOT crear backfill. Lock MUST ordenar con timeout, sin prometer atomicidad crash.

#### Scenario: Ciclo capturado
- GIVEN el runner ya ejecutó un test allowlisted
- WHEN registra campos válidos
- THEN MUST recalcular hash, generar UTC y anexar un evento
- AND MUST NOT ejecutar ni capturar el test

#### Scenario: Adopción operativa
- GIVEN un consumidor recién adoptado sin `tests/**` de B-IA
- WHEN ejecuta el self-check mediante el runner instalado
- THEN MUST registrar y verificar un evento allowlisted válido
- AND MUST permitir documentar locators relativos de tests propios del consumidor

#### Scenario: Entrada inválida
- GIVEN schema/tipo/fase/id/path/hash inválido, symlink o hardlink
- WHEN registra
- THEN MUST fallar sin modificar el ledger

#### Scenario: Ledger o concurrencia inválida
- GIVEN ledger sin LF final, corrupto, enlazado o lock agotado
- WHEN valida o anexa
- THEN MUST fallar cerrado sin prometer recuperación atómica

#### Scenario: Sin historia
- GIVEN un ciclo anterior o evento ausente
- WHEN consulta
- THEN MUST declarar ausencia y MUST NOT sintetizar backfill

### Requirement: Verificación

`verify` MUST comprobar; `archive` MUST bloquear divergencia o documentación pendiente.

#### Scenario: Fuente divergente
- GIVEN un destino distinto de su fuente declarada
- WHEN se verifica
- THEN MUST fallar e identificar el mapeo

### Requirement: Límite Codex

El incremento MUST limitarse a Codex, sin CLI ni multiproveedor.

#### Scenario: Inspección de alcance
- GIVEN los assets canónicos
- WHEN se inspeccionan
- THEN todos MUST corresponder a Codex
