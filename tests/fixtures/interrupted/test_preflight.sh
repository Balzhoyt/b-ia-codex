#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pre="$root/.bia/validators/preflight.sh"
test -x "$pre"

"$pre" --status-file "$root/tests/fixtures/dispatcher/allowed.json" --expect spec

set +e
"$pre" --status-file "$root/tests/fixtures/dispatcher/blocked.json" --expect spec; blocked=$?
"$pre" --status-file "$root/tests/fixtures/dispatcher/unknown.json" --read-only; unknown_read=$?
"$pre" --status-file "$root/tests/fixtures/dispatcher/unknown.json" --expect spec; unknown_write=$?
"$pre" --bad-option; usage=$?
set -e
test "$blocked" -eq 11
test "$unknown_read" -eq 3
test "$unknown_write" -eq 3
test "$usage" -eq 2

for skill in bia-explorar-idea bia-sdd-continuar; do
  file="$root/.agents/skills/$skill/SKILL.md"
  test -s "$file"
  grep -q 'Gentle AI' "$file"
  if grep -qiE 'Antigravity|Claude Code|\.codex/agents|implementa.*DAG' "$file"; then exit 1; fi
done
