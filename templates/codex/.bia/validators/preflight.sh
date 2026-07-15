#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=templates/codex/.bia/validators/common.sh
# shellcheck disable=SC1091
source "$here/common.sh"
# shellcheck source=templates/codex/.bia/validators/lib/dependencies.sh
# shellcheck disable=SC1091
source "$here/lib/dependencies.sh"

status_file=""; expected=""; read_only=false
while (($#)); do
  case "$1" in
    --status-file) (($# >= 2)) || bia_die "$BIA_USAGE" "Falta valor"; status_file="$2"; shift 2 ;;
    --expect) (($# >= 2)) || bia_die "$BIA_USAGE" "Falta fase"; expected="$2"; shift 2 ;;
    --read-only) read_only=true; shift ;;
    *) bia_die "$BIA_USAGE" "Opción inválida: $1" ;;
  esac
done
[[ -n "$status_file" ]] || bia_die "$BIA_USAGE" "Use --status-file"
bia_require_file "$status_file"
bia_require_dependencies jq

dispatcher="$(jq -ce 'if type == "object" then . else error("root-not-object") end' "$status_file" 2>/dev/null)" || bia_die "$BIA_DISPATCHER" "JSON del dispatcher inválido o incompleto"

if [[ "$(jq -r 'if has("source") then .source else "" end' <<< "$dispatcher")" == unknown ]]; then
  $read_only && printf 'Fuente unknown: informe degradado\n' >&2
  exit "$BIA_UNKNOWN"
fi

jq -e '
  has("blockedReasons") and (.blockedReasons | type == "array" and all(.[]; type == "string")) and
  has("nextRecommended") and (.nextRecommended | type == "string" and length > 0)
' <<< "$dispatcher" >/dev/null || bia_die "$BIA_DISPATCHER" "Contrato top-level del dispatcher inválido"

[[ "$(jq '.blockedReasons | length' <<< "$dispatcher")" -eq 0 ]] || bia_die "$BIA_DISPATCHER" "Dispatcher bloqueado"
actual="$(jq -r '.nextRecommended' <<< "$dispatcher")"
case "$actual" in
  resolve-blockers) bia_die "$BIA_DISPATCHER" "Dispatcher requiere resolver bloqueos" ;;
  propose|spec|design|tasks|apply|verify|archive) ;;
  *) bia_die "$BIA_DISPATCHER" "Recomendación inválida: $actual" ;;
esac
if [[ -n "$expected" && "$actual" != "$expected" ]]; then
  bia_die "$BIA_DISPATCHER" "Fase no autorizada: $expected"
fi
exit "$BIA_OK"
