#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

required=(
  templates/codex/AGENTS.md templates/codex/.bia/constitution.md templates/codex/.bia/policies/sdd.md
  templates/codex/.bia/policies/documentation.md templates/codex/.bia/policies/daily-work.md
  templates/codex/.bia/checklists/exploration.md templates/codex/.bia/checklists/artifact.md templates/codex/.bia/checklists/archive.md
)
for file in "${required[@]}"; do test -s "$root/$file"; done
grep -q 'único.*router\|único.*orquestador' "$root/templates/codex/AGENTS.md"
grep -q 'español' "$root/templates/codex/.bia/constitution.md"
grep -q 'canonical-source' "$root/templates/codex/.bia/constitution.md"
grep -q 'OpenSpec' "$root/templates/codex/.bia/policies/documentation.md"
grep -q 'America/Mexico_City' "$root/templates/codex/.bia/policies/daily-work.md"
test ! -e "$root/AGENTS.md"
test ! -d "$root/.bia"
if grep -RqiE '(/bia\.|Antigravity|Claude Code|\.codex/agents)' "$root/templates/codex/.bia" "$root/templates/codex/AGENTS.md"; then exit 1; fi

for fixture in valid global unclassified symlink escape; do
  test -e "$root/tests/fixtures/consumer/$fixture"
done
