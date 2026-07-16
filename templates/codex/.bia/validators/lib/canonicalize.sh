#!/usr/bin/env bash
set -euo pipefail
(($# == 1)) || { printf 'Uso: canonicalize.sh FILE\n' >&2; exit 2; }
[[ -f "$1" && ! -L "$1" ]] || exit 10
[[ "$(stat -c %h -- "$1" 2>/dev/null)" == 1 ]] || exit 10
sed 's/\r$//; s/[[:space:]]\+$//' -- "$1" | awk '
  { lines[NR]=$0 }
  END {
    last=NR
    while (last>0 && lines[last]=="") last--
    for (i=1; i<=last; i++) print lines[i]
  }'
