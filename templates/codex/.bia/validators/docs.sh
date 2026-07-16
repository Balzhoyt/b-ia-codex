#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$here/common.sh"
(($# >= 1)) || bia_die "$BIA_USAGE" "Uso: docs.sh DOCS_ROOT [--engram-decisions FILE]"
docs="$1"; shift; engram_decisions=""
while (($#)); do
  case "$1" in
    --engram-decisions) engram_decisions="${2:-}"; shift 2;;
    *) bia_die "$BIA_USAGE" "Opción documental inválida";;
  esac
done
[[ -d "$docs" ]] || bia_die "$BIA_POLICY" "Falta directorio documental"
if [[ -n "$engram_decisions" ]]; then
  bia_require_file "$engram_decisions"
  command -v jq >/dev/null || bia_die "$BIA_UNKNOWN" "Falta jq para validar decisiones"
  jq -e 'type == "array" and all(.[]; if .significant == true then (.durable_ref as $r | (($r|type) == "string" and ($r|length) > 0)) else true end)' "$engram_decisions" >/dev/null 2>&1 || bia_die "$BIA_POLICY" "Decisión permanente solo en Engram: durable_ref ausente, vacío o inválido"
  docs_real="$(realpath "$docs")"
  while IFS= read -r durable_ref; do
    case "$durable_ref" in /*|~*|*'..'*) bia_die "$BIA_POLICY" "Referencia durable insegura: $durable_ref";; esac
    durable_real="$(realpath -m "$docs/$durable_ref")"
    [[ "$durable_real" == "$docs_real/"* && -f "$durable_real" ]] || bia_die "$BIA_POLICY" "Referencia durable no resuelta: $durable_ref"
  done < <(jq -r '.[] | select(.significant == true) | .durable_ref' "$engram_decisions")
fi

if grep -RqsE 'DOCUMENTATION_PENDING|TODO-DOC|ADR_PENDING' "$docs"; then
  bia_die "$BIA_POLICY" "Documentación pendiente"
fi
while IFS= read -r file; do
  while IFS= read -r link; do
    case "$link" in http://*|https://*|mailto:*|'#'*) continue ;; esac
    target="${link%%#*}"
    [[ -z "$target" || -e "$(dirname "$file")/$target" ]] || bia_die "$BIA_POLICY" "Enlace roto en $file: $link"
  done < <(grep -Eo '\[[^]]+\]\([^)]+\)' "$file" | sed -E 's/^.*\(([^)]+)\)$/\1/' || true)
done < <(find "$docs" -type f -name '*.md' -print)

while IFS= read -r adr; do
  for section in Estado Contexto Decisión Consecuencias; do
    grep -Fqx "## $section" "$adr" || bia_die "$BIA_POLICY" "ADR incompleto: $adr ($section)"
  done
  grep -Eq '^(Propuesto|Aceptado|Rechazado|Sustituido)$' "$adr" || bia_die "$BIA_POLICY" "Estado ADR inválido: $adr"
done < <(find "$docs" -type f -name 'ADR-[0-9][0-9][0-9][0-9]-*.md' -print)
