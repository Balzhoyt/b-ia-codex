#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for skill in bia-explorar-idea bia-sdd-continuar; do
  source_file="$root/templates/codex/.agents/skills/$skill/SKILL.md"
  test -s "$source_file"
  grep -q '^name: ' "$source_file"
  grep -q 'Gentle AI' "$source_file"
  if grep -qiE 'Antigravity|Claude Code|\.codex/agents|implementa.*DAG' "$source_file"; then exit 1; fi
  mkdir -p "$tmp/.agents/skills/$skill"
  cp "$source_file" "$tmp/.agents/skills/$skill/SKILL.md"
  cmp "$source_file" "$tmp/.agents/skills/$skill/SKILL.md"
done
