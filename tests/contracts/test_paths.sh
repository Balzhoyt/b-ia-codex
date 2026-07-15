#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
paths="$root/templates/codex/.bia/validators/paths.sh"
pre="$root/templates/codex/.bia/validators/preflight.sh"
test -x "$paths"; test -x "$pre"
"$paths" canonical-source templates/codex/AGENTS.md AGENTS.md "$root"
set +e; "$paths" canonical-source templates/codex/../../outside AGENTS.md "$root"; traversal_code=$?; set -e
test "$traversal_code" -eq 10
printf -v literal_home '\x7e%s' '/.codex/skills/x'
for target in '../AGENTS.md' '/tmp/AGENTS.md' "$literal_home" '.codex/../outside'; do
  set +e; "$paths" canonical-source templates/codex/AGENTS.md "$target" "$root"; code=$?; set -e
  test "$code" -eq 10
done
set +e; "$paths" development-only templates/codex/AGENTS.md AGENTS.md "$root"; code=$?; set -e
test "$code" -eq 10
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/outside/codex" "$tmp/source-consumer"; ln -s "$tmp/outside" "$tmp/source-consumer/templates"
set +e; "$paths" canonical-source templates/codex/AGENTS.md AGENTS.md "$tmp/source-consumer" >/dev/null 2>&1; source_root_code=$?; set -e
test "$source_root_code" -eq 10
mkdir -p "$tmp/consumer"; ln -s /tmp "$tmp/consumer/linked"
set +e; "$paths" canonical-source templates/codex/AGENTS.md linked/AGENTS.md "$tmp/consumer"; code=$?; set -e
mkdir -p "$tmp/dangling-consumer"; ln -s inside/missing "$tmp/dangling-consumer/linked"
set +e; "$paths" canonical-source templates/codex/AGENTS.md linked/AGENTS.md "$tmp/dangling-consumer" >/dev/null 2>&1; dangling_code=$?; set -e
test "$dangling_code" -eq 10
test "$code" -eq 10
"$pre" --status-file "$root/tests/fixtures/dispatcher/allowed.json" --expect spec
set +e; "$pre" --status-file "$root/tests/fixtures/dispatcher/blocked.json" --expect spec; code=$?; set -e
test "$code" -eq 11
