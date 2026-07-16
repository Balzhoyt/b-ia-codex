## Exploración: Gobernanza SDD Codex-first compatible con Gentle AI y OpenSpec

### Estado actual
El repositorio ya usa modo híbrido y el dispatcher reconoce `proposal.md` y `specs/**/spec.md`; `gentle-ai sdd-status ... --json --instructions` devuelve `nextRecommended: design`. La propuesta limita el MVP a Codex, skills `$bia-*` y agentes especializados.

Codex no descubre reglas desde una carpeta arbitraria. Los puntos de entrada reconocidos son `AGENTS.md` para instrucciones duraderas, `.agents/skills/**/SKILL.md` para workflows reutilizables y `.codex/config.toml` para configuración del proyecto y agentes en repositorios confiables. Los Markdown referenciados son contexto auxiliar: no se autodetectan por estar dentro del repositorio.

### Áreas afectadas
- `AGENTS.md` — contrato raíz: idioma, persistencia híbrida, selección de cambio y obligación de validar antes de avanzar.
- `.agents/skills/bia-*/SKILL.md` — workflows invocables para explorar, proponer, especificar, diseñar, planificar, aplicar, verificar y archivar.
- `.codex/config.toml` y archivos de agente referenciados — especialización opcional; no sustituyen las skills ni el dispatcher.
- `openspec/config.yaml` — contexto y reglas por fase.
- `openspec/changes/{change}/` — artefactos activos y `state.yaml`.
- `openspec/specs/` y `openspec/changes/archive/` — especificaciones vigentes y auditoría final.

### Enfoques
1. **Solo instrucciones Markdown** — las skills escriben archivos según ejemplos.
   - Ventajas: mínimo, revisable y sin runtime propio.
   - Desventajas: una instrucción puede omitirse; no prueba rutas, YAML, dependencias, sincronía híbrida ni evidencia de ejecución.
   - Esfuerzo: Bajo.

2. **Gobernanza Markdown más validación existente** — las skills producen artefactos y consultan `gentle-ai sdd-status` antes de enrutar; OpenSpec queda como fuente de verdad visible y Engram como recuperación.
   - Ventajas: conserva el MVP sin CLI propia y reutiliza contratos ya compatibles.
   - Desventajas: requiere Gentle AI para validación completa y herramientas Engram para la segunda escritura.
   - Esfuerzo: Medio.

3. **Motor SDD propio** — reimplementar dispatcher, esquema, sincronización y archivo.
   - Ventajas: control total.
   - Desventajas: recrea la CLI ambiciosa descartada y duplica Gentle AI.
   - Esfuerzo: Alto.

### Recomendación
Adoptar el enfoque 2. Las reglas y skills deben ser la **capa de gobernanza**, no presentarse como mecanismo de cumplimiento. La arquitectura mínima es:

```text
AGENTS.md
.agents/skills/
├── bia-explorar-idea/SKILL.md
└── bia-sdd-continuar/SKILL.md
.codex/config.toml                 # solo si se delegan roles especializados
instructions/sdd/
└── artifact-contracts.md          # referencia explícita, no autodetectable
openspec/
├── config.yaml
├── specs/
└── changes/archive/
```

`$bia-explorar-idea` inicia o refina la intención. `$bia-sdd-continuar` consulta estado estructurado y enruta a la fase indicada. Las fases pueden vivir como secciones internas al principio; separarlas en ocho skills solo cuando necesiten invocación pública o mantenimiento independiente.

Compatibilidad obligatoria:

- Cambio activo: `state.yaml`, `proposal.md`, `specs/{capability}/spec.md`, `design.md`, `tasks.md` y `verify-report.md` en las rutas OpenSpec exactas.
- Aplicación: actualizar inmediatamente los checkboxes de `tasks.md`; en híbrido guardar además `sdd/{change}/apply-progress` en Engram.
- Engram: usar topic keys deterministas `sdd/{change}/{artifact}` y recuperar siempre el contenido completo después de buscar.
- Archivo: bloquear tareas pendientes o verificación con CRITICAL; fusionar deltas en `openspec/specs/` antes de mover el cambio a `archive/YYYY-MM-DD-{change}/`.
- Routing: con `hybrid`, el dispatcher de Gentle AI lee OpenSpec y su estado estructurado es autoritativo; no inferir la siguiente fase desde texto libre.

### Riesgos
- Markdown puede orientar a la IA, pero no garantizar cumplimiento. Rutas, YAML, referencias, checkboxes, comandos de prueba y sincronía Engram/OpenSpec requieren validación o herramientas.
- El dispatcher no lee Engram ni las skills; solo observa los artefactos OpenSpec. Una escritura híbrida queda incompleta si falla cualquiera de los dos backends.
- `apply-progress` tiene contrato persistente en Engram, mientras la evidencia humana mínima en OpenSpec es `tasks.md`; no debe inventarse un archivo adicional salvo que el dispatcher lo reconozca.
- Los agentes especializados son una optimización de ejecución. El contrato de artefactos debe permanecer independiente del agente que lo produzca.

### Listo para propuesta
Sí. La propuesta y la especificación deben ampliarse para declarar gobernanza SDD compatible con Gentle AI/OpenSpec, persistencia híbrida y validación estructural, sin introducir una CLI propia.
