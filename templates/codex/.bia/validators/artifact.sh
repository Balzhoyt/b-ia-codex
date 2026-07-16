#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$here/common.sh"

usage="Uso: artifact.sh FILE [--section NAME] [--base DIR]"
(($# >= 1)) || bia_die "$BIA_USAGE" "$usage"
file="$1"
shift
section=""
base="$(dirname "$file")"
seen_section=0
seen_base=0
while (($#)); do
  case "$1" in
    --section)
      (($# >= 2 && seen_section == 0)) || bia_die "$BIA_USAGE" "$usage"
      section="$2"; seen_section=1; shift 2 ;;
    --base)
      (($# >= 2 && seen_base == 0)) || bia_die "$BIA_USAGE" "$usage"
      base="$2"; seen_base=1; shift 2 ;;
    *) bia_die "$BIA_USAGE" "Opción inválida: $1" ;;
  esac
done

[[ -d "$base" && ! -L "$base" ]] || bia_die "$BIA_POLICY" "Base inválida: $base"
[[ -f "$file" && ! -L "$file" ]] || bia_die "$BIA_POLICY" "Falta archivo requerido: $file"
[[ "$(stat -c %h -- "$file")" -eq 1 ]] || bia_die "$BIA_POLICY" "Artefacto con alias físico: $file"
base_real="$(readlink -f -- "$base")" || bia_die "$BIA_POLICY" "Base inválida: $base"
file_real="$(readlink -f -- "$file")" || bia_die "$BIA_POLICY" "Archivo inválido: $file"
case "$file_real" in "$base_real"/*) ;; *) bia_die "$BIA_POLICY" "Artefacto fuera de la base: $file" ;; esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
content="$work/content"
links="$work/links"
definitions="$work/definitions"

awk '
  function prepare(line) { sub(/^[ ]{0,3}/, "", line); return line }
  function run_length(line, char, n) {
    n=0
    while (substr(line, n+1, 1) == char) n++
    return n
  }
  {
    line=prepare($0)
    if (!fence) {
      char=substr(line, 1, 1)
      if (char == "`" || char == "~") {
        count=run_length(line, char)
        if (count >= 3) { fence=char; opening=count; next }
      }
      print
      next
    }
    if (substr(line, 1, 1) == fence) {
      count=run_length(line, fence)
      tail=substr(line, count+1)
      if (count >= opening && tail ~ /^[ \t]*$/) { fence=""; opening=0 }
    }
  }
  END { if (fence) exit 4 }
' "$file_real" >"$content" || bia_die "$BIA_POLICY" "Bloque Markdown sin cierre"

head -n1 "$content" | grep -Eq '^# [^#]' || bia_die "$BIA_POLICY" "Falta título H1"
[[ -z "$section" ]] || grep -Fqx "## $section" "$content" || bia_die "$BIA_POLICY" "Falta sección: $section"
# Deterministic evidence contract, not general-purpose linguistic classification.
tokens="$work/tokens"
awk '!/^[[:space:]]*#/ { print }' "$content" | sed -E 's/[Áá]/a/g; s/[Éé]/e/g; s/[Íí]/i/g; s/[Óó]/o/g; s/[ÚúÜü]/u/g; s/[Ññ]/n/g' | \
  LC_ALL=C tr -cs 'A-Za-z' '\n' | tr '[:upper:]' '[:lower:]' | sort -u >"$tokens"
function_words="$(grep -Exc '(el|la|los|las|de|del|y|para|con|sin|un|una|que|se|por)' "$tokens" || true)"
domain_words="$(grep -Exc '(artefacto|contenido|evidencia|decision|trabajo|valido|valida|verificable|referencia|documento|describe|realizado)' "$tokens" || true)"
((function_words >= 3 && domain_words >= 2)) || bia_die "$BIA_POLICY" "No hay evidencia determinista de español profesional"

awk '
  {
    start=1
    while (match(substr($0, start), /\]\(/)) {
      open=start+RSTART
      depth=1; payload=""; escaped=0
      for (i=open+1; i<=length($0); i++) {
        char=substr($0, i, 1)
        if (escaped) { payload=payload char; escaped=0; continue }
        if (char == "\\") { payload=payload char; escaped=1; continue }
        if (char == "(") depth++
        if (char == ")") { depth--; if (depth == 0) break }
        payload=payload char
      }
      if (depth != 0) exit 5
      print payload
      start=i+1
    }
  }
' "$content" >"$links" || bia_die "$BIA_POLICY" "Enlace Markdown malformado"

validate_target() {
  local link="$1" target candidate candidate_real lower
  target="${link%%#*}"; [[ -n "$target" ]] || return 0
  lower="${target,,}"
  case "$lower" in http://*|https://*|mailto:*|'#'*) return 0 ;; esac
  case "$target" in /*|~*) bia_die "$BIA_POLICY" "Referencia fuera de la base: $link" ;; esac
  candidate="$base_real/$target"
  [[ -f "$candidate" && ! -L "$candidate" ]] || bia_die "$BIA_POLICY" "Referencia inválida: $link"
  [[ "$(stat -c %h -- "$candidate")" -eq 1 ]] || bia_die "$BIA_POLICY" "Referencia con alias físico: $link"
  candidate_real="$(readlink -f -- "$candidate")" || bia_die "$BIA_POLICY" "Referencia inválida: $link"
  case "$candidate_real" in "$base_real"/*) ;; *) bia_die "$BIA_POLICY" "Referencia fuera de la base: $link" ;; esac
}

parse_payload() {
  local payload="$1" rest
  payload="${payload#"${payload%%[![:space:]]*}"}"
  if [[ "$payload" == \<* ]]; then
    [[ "$payload" == *\>* ]] || bia_die "$BIA_POLICY" "Destino Markdown malformado"
    target="${payload#<}"; target="${target%%>*}"; rest="${payload#*>}"
  else
    target="${payload%%[[:space:]]*}"; rest="${payload#"$target"}"
  fi
  [[ -n "$target" ]] || bia_die "$BIA_POLICY" "Destino Markdown vacío"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  [[ -z "$rest" ]] && return 0
  case "$rest" in \"*\"|\'*\'|\(*\)) ;; *) bia_die "$BIA_POLICY" "Título Markdown malformado" ;; esac
}

while IFS= read -r payload; do parse_payload "$payload"; validate_target "$target"; done <"$links"

: >"$definitions"
while IFS= read -r definition; do
  id="${definition%%]:*}"; id="${id#*[}"
  normalized="$(printf '%s\n' "$id" | tr '[:upper:]' '[:lower:]' | awk '{$1=$1; print}')"
  grep -Fqx "$normalized" "$definitions" && bia_die "$BIA_POLICY" "Definición duplicada: $id"
  printf '%s\n' "$normalized" >>"$definitions"
  payload="${definition#*:}"; parse_payload "$payload"; validate_target "$target"
done < <(grep -E '^[[:space:]]*\[[^]]+\]:[[:space:]]*' "$content" || true)

while IFS= read -r reference; do
  label="${reference%%]*}"; label="${label#*[}"
  id="${reference##*\[}"; id="${id%]}"; [[ -n "$id" ]] || id="$label"
  normalized="$(printf '%s\n' "$id" | tr '[:upper:]' '[:lower:]' | awk '{$1=$1; print}')"
  grep -Fqx "$normalized" "$definitions" || bia_die "$BIA_POLICY" "Referencia sin definición: $id"
done < <(grep -Eo '\[[^]]+\]\[[^]]*\]' "$content" || true)

shortcut_view="$work/shortcut-view"
grep -Ev '^[[:space:]]*\[[^]]+\]:' "$content" | sed -E 's/\[[^]]+\]\([^)]*\)//g; s/\[[^]]+\]\[[^]]*\]//g' >"$shortcut_view"
grep -Eq '(^|[[:space:]])\[[^]]+\]([[:space:][:punct:]]|$)' "$shortcut_view" && \
  bia_die "$BIA_POLICY" "Referencias abreviadas no admitidas"

exit "$BIA_OK"
