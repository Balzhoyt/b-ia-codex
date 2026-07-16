#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
archive="$root/openspec/changes/archive/2026-07-13-ai-agnostic-project-bootstrap"
progress="$archive/apply-progress.md"
grep -Fq '## TDD Cycle Evidence' "$progress"
for column in 'Archivo de prueba' 'Capa' 'Safety net' 'Triangulación' 'GREEN ejecutado'; do grep -Fq "$column" "$progress"; done
for task in 1.1 1.2 1.3 2.1 2.2 2.3 2.4 2.5 3.1 3.2 3.3 4.1 4.2 4.3 4.4; do
  grep -Eq '^\| '"$task"' \|' "$progress"
done
grep -Fq 'Limitación de evidencia' "$progress"
state="$archive/state.yaml"
grep -Fq '    - "4.4"' "$state"
grep -Fq '  pending: []' "$state"
grep -Fq 'phase: archive' "$state"
grep -Fq '  status: complete' "$state"
grep -Fq 'next_recommended: none' "$state"
test -s "$archive/archive-report.md"
