#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
worklog="$root/templates/codex/.bia/validators/worklog.sh"
evidence="$root/templates/codex/.bia/validators/lib/evidence.sh"
test -x "$worklog"; test -x "$evidence"
test "$("$evidence" identity git abc d1)" = 'git|abc|d1'
test "$(TZ=America/Mexico_City "$worklog" date)" = "$(TZ=America/Mexico_City date +%F)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cp "$root/tests/fixtures/worklog/evidence.json" "$tmp/evidence.json"
"$worklog" render 2026-07-12 "$tmp/evidence.json" "$tmp/day.md" dispatcher
first="$(sha256sum "$tmp/day.md" | cut -d' ' -f1)"
"$worklog" render 2026-07-12 "$tmp/evidence.json" "$tmp/day.md" dispatcher
second="$(sha256sum "$tmp/day.md" | cut -d' ' -f1)"
test "$first" = "$second"
test "$(grep -c 'evidence:git|abc123|d1' "$tmp/day.md")" -eq 1
grep -q 'Fuente no disponible: dispatcher' "$tmp/day.md"
cat > "$tmp/invalid.json" <<'EOF'
[{"source":"git","locator":"abc123","observed_at":"2026-07-12T10:00:00-06:00","digest":"","status":"completed","summary":"Sin digest"}]
EOF
set +e; "$worklog" render 2026-07-12 "$tmp/invalid.json" "$tmp/invalid.md"; invalid=$?; set -e
test "$invalid" -eq 10
base='{"source":"git","locator":"abc123","observed_at":"2026-07-12T10:00:00-06:00","digest":"d1","status":"completed","summary":"Completo"}'
for field in source locator digest status summary observed_at; do
  printf '[%s]\n' "$(printf '%s' "$base" | sed -E 's/,?"'"$field"'":"[^"]*"//; s/\{,/\{/')" > "$tmp/missing-$field.json"
  set +e; "$worklog" render 2026-07-12 "$tmp/missing-$field.json" "$tmp/missing-$field.md"; missing=$?; set -e
  test "$missing" -eq 10
done
printf '[%s]\n' "${base/\"completed\"/\"misterioso\"}" > "$tmp/unknown-status.json"
set +e; "$worklog" render 2026-07-12 "$tmp/unknown-status.json" "$tmp/unknown.md"; unknown=$?; set -e
test "$unknown" -eq 10
cat > "$tmp/duplicate.json" <<'EOF'
[{"source":"git","locator":"abc123","observed_at":"2026-07-12T10:00:00-06:00","digest":"d1","status":"completed","summary":"Primero"},{"source":"git","locator":"abc123","observed_at":"2026-07-12T11:00:00-06:00","digest":"d1","status":"completed","summary":"Segundo"}]
EOF
"$worklog" render 2026-07-12 "$tmp/duplicate.json" "$tmp/duplicate.md"
test "$(grep -c 'evidence:git|abc123|d1' "$tmp/duplicate.md")" -eq 1
for skill in bia-iniciar-trabajo bia-finalizar-trabajo; do
  file="$root/templates/codex/.agents/skills/$skill/SKILL.md"
  test -s "$file"; grep -q 'Gentle AI' "$file"; grep -q 'commit' "$file"
done
