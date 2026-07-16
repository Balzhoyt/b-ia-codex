#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
validator="$root/templates/codex/.bia/validators/docs.sh"
test -x "$validator"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/docs/decisions"
cat > "$tmp/docs/decisions/ADR-0001-demo.md" <<'EOF'
# ADR-0001: Demostración
## Estado
Aceptado
## Contexto
Contexto verificado.
## Decisión
Usar una demostración.
## Consecuencias
Resultado trazable.
EOF
printf '# Índice\n\n[Decisión](decisions/ADR-0001-demo.md)\n' > "$tmp/docs/README.md"
"$validator" "$tmp/docs"
printf '[{"significant":true,"summary":"Persistencia elegida","durable_ref":""}]\n' > "$tmp/engram.json"
set +e; "$validator" "$tmp/docs" --engram-decisions "$tmp/engram.json"; memory_only=$?; set -e
test "$memory_only" -eq 10
printf '[{"significant":true,"summary":"Sin campo"}]\n' > "$tmp/engram-omitted.json"
set +e; "$validator" "$tmp/docs" --engram-decisions "$tmp/engram-omitted.json"; omitted=$?; set -e
test "$omitted" -eq 10
printf '[{"significant":true,"summary":"Tipo inválido","durable_ref":7}]\n' > "$tmp/engram-type.json"
set +e; "$validator" "$tmp/docs" --engram-decisions "$tmp/engram-type.json"; wrong_type=$?; set -e
test "$wrong_type" -eq 10
printf '[{"significant":true,"summary":"Referencia ausente","durable_ref":"decisions/no-existe.md"}]\n' > "$tmp/engram-missing.json"
set +e; "$validator" "$tmp/docs" --engram-decisions "$tmp/engram-missing.json"; missing_ref=$?; set -e
test "$missing_ref" -eq 10
printf '[{"significant":true,"summary":"Documentada","durable_ref":"decisions/ADR-0001-demo.md"}]\n' > "$tmp/engram-valid.json"
"$validator" "$tmp/docs" --engram-decisions "$tmp/engram-valid.json"
printf '\nDOCUMENTATION_PENDING\n' >> "$tmp/docs/README.md"
set +e; "$validator" "$tmp/docs"; pending=$?; set -e
test "$pending" -eq 10

for file in project/overview.md project/architecture.md project/development.md project/testing.md decisions/README.md decisions/ADR-template.md worklog/README.md worklog/templates/day.md; do
  test -s "$root/templates/codex/docs/$file"
done
development="$root/templates/codex/docs/project/development.md"
grep -Fq 'SHA-256 esperado para rollback:' "$development"
grep -Fq 'fuera de `.bia-backup` y del repositorio consumidor' "$development"
grep -Fq 'Sin ese digest, el rollback falla de forma segura' "$development"
grep -Fq '.bia/adoption/rollback.sh --consumer "$PWD" --record "$record" --record-sha256 "$record_sha256"' "$development"
"$validator" "$root/templates/codex/docs"
