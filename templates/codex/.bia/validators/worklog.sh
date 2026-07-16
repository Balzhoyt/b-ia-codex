#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$here/common.sh"
command="${1:-}"; shift || true
case "$command" in
  date)
    TZ=America/Mexico_City date +%F
    ;;
  render)
    (($# >= 3)) || bia_die "$BIA_USAGE" "render DATE EVIDENCE OUTPUT [UNKNOWN...]"
    day="$1"; input="$2"; output="$3"; shift 3
    bia_require_file "$input"
    command -v jq >/dev/null || bia_die "$BIA_UNKNOWN" "Falta jq para validar evidencia"
    tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
    jq -e '
      type == "array" and all(.[];
        (.source | type == "string" and length > 0) and
        (.locator | type == "string" and length > 0) and
        (.digest | type == "string" and length > 0) and
        (.status | type == "string" and IN("completed","in_progress","blocked","decision")) and
        (.summary | type == "string" and length > 0) and
        (.observed_at | type == "string" and length > 0)
      )' "$input" >/dev/null 2>&1 || bia_die "$BIA_POLICY" "Evidencia incompleta o status desconocido"
    jq -r '.[] | [.status, .summary, (.source + "|" + .locator + "|" + .digest), .observed_at] | @tsv' "$input" |
      sort -t $'\t' -k3,3 -k4,4r | awk -F '\t' '!seen[$3]++' > "$tmp"
    revised="$(cut -f4 "$tmp" | sort | tail -n1)"
    {
      printf '# Bitácora — %s\n\n' "$day"
      # shellcheck disable=SC2016
      printf 'Zona horaria: `America/Mexico_City`  \nRevisado: `%s`\n\n' "${revised:-sin evidencia}"
      for pair in 'completed:Completado' 'in_progress:En progreso' 'blocked:Bloqueado' 'decision:Decisiones'; do
        status="${pair%%:*}"; title="${pair#*:}"; printf '## %s\n\n' "$title"
        found=false
        while IFS=$'\t' read -r got summary id observed; do
          [[ "$got" == "$status" ]] || continue
          # shellcheck disable=SC2016
          printf -- '- %s (`%s`) <!-- evidence:%s -->\n' "$summary" "$observed" "$id"; found=true
        done < "$tmp"
        $found || printf -- '- Sin evidencia verificada.\n'
        printf '\n'
      done
      printf '## Fuentes parciales\n\n'
      if (($#)); then for missing in "$@"; do printf -- '- Fuente no disponible: %s.\n' "$missing"; done; else printf -- '- Ninguna.\n'; fi
      # shellcheck disable=SC2016
      printf '\n## Siguiente paso\n\n- Consultar `nextRecommended` de Gentle AI; no ejecutar automáticamente.\n'
    } > "$output"
    ;;
  *) bia_die "$BIA_USAGE" "Comando worklog inválido" ;;
esac
