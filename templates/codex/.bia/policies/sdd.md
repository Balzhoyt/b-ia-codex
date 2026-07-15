# Política SDD

- Consultar `gentle-ai sdd-status <cambio> --cwd <repo> --json --instructions`.
- Ejecutar únicamente `nextRecommended` cuando `blockedReasons` esté vacío.
- Los roles especializados no eligen fases, no aprueban su salida y no escriben estado SDD.
- `apply`, `archive`, commit y publicación requieren todas las fuentes conocidas y validaciones en código `0`.
- B-IA envuelve las fases oficiales; no implementa un DAG ni una CLI.
