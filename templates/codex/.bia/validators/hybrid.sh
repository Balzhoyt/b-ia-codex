#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Installed template resolves the sibling library at runtime.
# shellcheck disable=SC1091
source "$here/common.sh"
canon="$here/lib/canonicalize.sh"

regular_file() {
  [[ -s "$1" && -f "$1" && ! -L "$1" ]] || bia_die "$BIA_POLICY" "Se requiere un archivo regular no vacío"
  [[ "$(stat -c %h -- "$1" 2>/dev/null)" == 1 ]] || bia_die "$BIA_POLICY" "No se permiten hardlinks"
}

canonical_hash() { "$canon" "$1" | sha256sum | cut -d' ' -f1; }

safe_target() {
  local root="$1" relative="$2" mode="$3" physical component cursor target
  [[ "$root" == /* && -d "$root" && ! -L "$root" ]] || bia_die "$BIA_POLICY" "Raíz confiable inválida"
  physical="$(realpath -e -- "$root" 2>/dev/null)" || bia_die "$BIA_POLICY" "Raíz confiable inválida"
  [[ "$root" == "$physical" ]] || bia_die "$BIA_POLICY" "La raíz confiable contiene enlaces"
  [[ -n "$relative" && "$relative" != /* && "/$relative/" != *'/../'* && "/$relative/" != *'/./'* ]] || bia_die "$BIA_POLICY" "Destino pending fuera de la raíz"
  [[ "$(basename -- "$relative")" == *.pending ]] || bia_die "$BIA_POLICY" "El destino debe terminar en .pending"
  target="$(realpath -m -- "$physical/$relative")"
  [[ "$target" == "$physical/"* ]] || bia_die "$BIA_POLICY" "Destino pending fuera de la raíz"
  cursor="$physical"
  IFS='/' read -r -a components <<< "$(dirname -- "$relative")"
  for component in "${components[@]}"; do
    [[ -n "$component" ]] || continue
    cursor="$cursor/$component"
    [[ ! -L "$cursor" ]] || bia_die "$BIA_POLICY" "Ancestro pending inseguro"
    if [[ ! -e "$cursor" ]]; then mkdir -- "$cursor"; fi
    [[ -d "$cursor" && ! -L "$cursor" ]] || bia_die "$BIA_POLICY" "Ancestro pending inseguro"
  done
  [[ ! -L "$target" ]] || bia_die "$BIA_POLICY" "Destino pending inseguro"
  if [[ "$mode" == stage ]]; then
    [[ ! -e "$target" ]] || bia_die "$BIA_POLICY" "Pending ya existe"
  else
    [[ -f "$target" && "$(stat -c %h -- "$target" 2>/dev/null)" == 1 ]] || bia_die "$BIA_POLICY" "Pending recuperable ausente"
  fi
  printf '%s\n' "$target"
}

atomic_copy() {
  local source="$1" target="$2" temporary
  regular_file "$source"
  # Namespace-atomic only, not crash-durable: callers must prevent concurrent
  # trusted-root mutation because Bash cannot descriptor-pin path ancestors.
  temporary="$(mktemp "$(dirname -- "$target")/.bia-pending.XXXXXX")"
  trap 'rm -f -- "${temporary:-}"' EXIT
  cp -- "$source" "$temporary"
  mv -fT -- "$temporary" "$target"
  trap - EXIT
}

command="${1:-}"; shift || true
case "$command" in
  compare)
    (($# == 2)) || bia_die "$BIA_USAGE" "compare requiere dos archivos"
    regular_file "$1"; regular_file "$2"
    a="$(canonical_hash "$1")"
    b="$(canonical_hash "$2")"
    [[ "$a" == "$b" ]] || bia_die "$BIA_HYBRID" "Copias híbridas divergentes"
    ;;
  validate-engram)
    (($# == 3)) || bia_die "$BIA_USAGE" "validate-engram requiere JSON, topic_key y contenido completo"
    json="$1"; expected_topic="$2"; expected_content="$3"
    regular_file "$json"; regular_file "$expected_content"
    command -v jq >/dev/null || bia_die "$BIA_UNKNOWN" "Falta jq para validar Engram"
    active_object="$(jq -ce '
      if (.results|type) != "array" or (.results|length) == 0 then error("results")
      elif all(.results[]; type == "object" and (.id|type == "number" and . > 0 and floor == .) and (.state|type == "string") and (.topic_key|type == "string") and (.content|type == "string") and (.content_sha256|type == "string" and test("^[0-9a-f]{64}$"))) | not then error("schema")
      else [.results[] | select(.state == "active")] | if length == 1 then .[0] else error("active-count") end end' "$json" 2>/dev/null)" || bia_die "$BIA_HYBRID" "Engram requiere esquema válido y un resultado activo único"
    jq -e '(.id != null) and (.topic_key | type == "string") and (.content | type == "string") and (.content_sha256 | type == "string" and test("^[0-9a-f]{64}$"))' <<< "$active_object" >/dev/null || bia_die "$BIA_HYBRID" "El objeto activo carece de identidad, topic_key, contenido o hash"
    topic="$(jq -r '.topic_key' <<< "$active_object")"
    [[ "$topic" == "$expected_topic" ]] || bia_die "$BIA_HYBRID" "topic_key inesperado"
    decoded="$(mktemp)"; trap 'rm -f "$decoded"' EXIT
    jq -j '.content' <<< "$active_object" > "$decoded"
    declared="$(jq -r '.content_sha256' <<< "$active_object")"
    [[ "$declared" == "$(canonical_hash "$decoded")" && "$declared" == "$(canonical_hash "$expected_content")" ]] || bia_die "$BIA_HYBRID" "Hash o contenido Engram alterado"
    "$0" compare "$decoded" "$expected_content" || bia_die "$BIA_HYBRID" "Contenido Engram alterado"
    ;;
  recover)
    (($# == 3)) || bia_die "$BIA_USAGE" "recover requiere raíz, OpenSpec y pending relativo"
    target="$(safe_target "$1" "$3" recover)"
    atomic_copy "$2" "$target"
    ;;
  stage)
    (($# == 3)) || bia_die "$BIA_USAGE" "stage requiere raíz, origen y pending relativo"
    target="$(safe_target "$1" "$3" stage)"
    atomic_copy "$2" "$target"
    ;;
  *) bia_die "$BIA_USAGE" "Comando híbrido inválido" ;;
esac
