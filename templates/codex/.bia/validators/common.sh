#!/usr/bin/env bash

# Constants are consumed by scripts that source this shared library.
# shellcheck disable=SC2034
readonly BIA_OK=0
readonly BIA_USAGE=2
readonly BIA_UNKNOWN=3
readonly BIA_POLICY=10
readonly BIA_DISPATCHER=11
readonly BIA_HYBRID=12

bia_root() { git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null; }
bia_die() { local code="$1"; shift; printf 'B-IA: %s\n' "$*" >&2; exit "$code"; }
bia_require_file() { [[ -s "$1" ]] || bia_die "$BIA_POLICY" "Falta archivo requerido: $1"; }
