#!/usr/bin/env bash
set -euo pipefail
command="${1:-}"; shift || true
case "$command" in
  identity) (($# == 3)) || exit 2; printf '%s|%s|%s\n' "$1" "$2" "$3" ;;
  priority)
    case "${1:-}" in blocked) echo 1;; in_progress) echo 2;; completed) echo 3;; decision) echo 4;; *) echo 9;; esac ;;
  *) printf 'Uso: evidence.sh {identity|priority}\n' >&2; exit 2 ;;
esac
