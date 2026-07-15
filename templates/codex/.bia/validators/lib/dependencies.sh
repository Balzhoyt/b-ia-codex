#!/usr/bin/env bash

bia_dependency_available() {
  local dependency="$1"
  command -v "$dependency" >/dev/null 2>&1
}

bia_require_dependencies() {
  local dependency
  for dependency in "$@"; do
    bia_dependency_available "$dependency" || bia_die "$BIA_UNKNOWN" "Dependencia declarada ausente: $dependency"
  done
}
