#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
validators="$(cd "$here/../validators" && pwd)"
# shellcheck source=/dev/null
source "$validators/common.sh"
# shellcheck source=/dev/null
source "$validators/lib/dependencies.sh"

root=""; consumer=""; manifest=""; dry_run=false
while (($#)); do
  case "$1" in
    --root) root="${2:-}"; shift 2;;
    --consumer) consumer="${2:-}"; shift 2;;
    --manifest) manifest="${2:-}"; shift 2;;
    --dry-run) dry_run=true; shift;;
    *) bia_die "$BIA_USAGE" "Opción inválida: $1";;
  esac
done
[[ -n "$root" && -n "$consumer" && -n "$manifest" ]] || bia_die "$BIA_USAGE" "Faltan --root, --consumer o --manifest"
root="$(realpath "$root")"; consumer="$(realpath "$consumer")"; manifest="$(realpath "$manifest")"
bia_require_dependencies git codex gentle-ai engram jq sha256sum sync stat id date realpath sleep
git -C "$consumer" rev-parse --show-toplevel >/dev/null 2>&1 || bia_die "$BIA_UNKNOWN" "El consumidor no es repositorio Git"

inventory_tmp="$(mktemp -d)"; trap 'rm -rf "$inventory_tmp"' EXIT
find "$root/templates/codex" -type f -printf '%p\n' | sed "s#^$root/##" | sort > "$inventory_tmp/canonical"
awk -F '\t' '$1=="canonical-source" {print $2}' "$manifest" | sort > "$inventory_tmp/declared"
duplicates="$(uniq -d "$inventory_tmp/declared")"
[[ -z "$duplicates" ]] || bia_die "$BIA_POLICY" "Fuentes duplicadas en manifiesto: $duplicates"
awk -F '\t' '$1=="canonical-source" {print $3}' "$manifest" | sort > "$inventory_tmp/destinations"
duplicate_destinations="$(uniq -d "$inventory_tmp/destinations")"
[[ -z "$duplicate_destinations" ]] || bia_die "$BIA_POLICY" "Destinos duplicados en manifiesto: $duplicate_destinations"
comm -3 "$inventory_tmp/canonical" "$inventory_tmp/declared" > "$inventory_tmp/diff"
[[ ! -s "$inventory_tmp/diff" ]] || bia_die "$BIA_POLICY" "Manifiesto incompleto o extra: $(tr '\n' ' ' < "$inventory_tmp/diff")"

validate_consumer_destination() {
  local destination="$1" current="$consumer" component
  IFS='/' read -r -a components <<< "$destination"
  for component in "${components[@]:0:${#components[@]}-1}"; do
    current="$current/$component"
    if [[ -e "$current" || -L "$current" ]]; then
      [[ -d "$current" && ! -L "$current" ]] || bia_die "$BIA_POLICY" "Componente de destino inseguro: $destination"
    fi
  done
  current="$consumer/$destination"
  if [[ -e "$current" || -L "$current" ]]; then
    [[ -f "$current" && ! -L "$current" && "$(stat -c %h -- "$current" 2>/dev/null)" == 1 ]] || \
      bia_die "$BIA_POLICY" "Destino existente inseguro: $destination"
  fi
}

while IFS=$'\t' read -r class source_path destination mode; do
  [[ -n "$class" && "${class:0:1}" != '#' ]] || continue
  "$validators/paths.sh" "$class" "$source_path" "$destination" "$consumer"
  source_real="$(realpath "$root/$source_path")"
  [[ "$source_real" == "$root/templates/codex/"* && -f "$source_real" ]] || bia_die "$BIA_POLICY" "Fuente inválida: $source_path"
  [[ "$mode" == copy || "$mode" == managed-append ]] || bia_die "$BIA_POLICY" "Modo inválido: $mode"
  validate_consumer_destination "$destination"
done < "$manifest"

$dry_run && { printf 'Dry-run válido: no se escribieron archivos.\n'; exit 0; }
stamp="$(TZ=America/Mexico_City date +%Y%m%dT%H%M%S)-$$"
backup="$consumer/.bia-backup/$stamp"; record="$backup/adoption-record.tsv"
mkdir -p "$backup"; : > "$record"

while IFS=$'\t' read -r class source_path destination mode; do
  [[ -n "$class" && "${class:0:1}" != '#' ]] || continue
  source_real="$root/$source_path"; target="$consumer/$destination"
  parent_rel="$(dirname "$destination")"; current="$consumer"; built=""
  if [[ "$parent_rel" != . ]]; then
    IFS='/' read -r -a components <<< "$parent_rel"
    for component in "${components[@]}"; do
      built="${built:+$built/}$component"; current="$consumer/$built"
      if [[ ! -e "$current" ]]; then
        mkdir "$current"; printf 'mkdir\t%s\t-\n' "$built" >> "$record"
      fi
    done
  fi
  if [[ -e "$target" ]]; then
    mkdir -p "$backup/original/$(dirname "$destination")"
    cp -a -- "$target" "$backup/original/$destination"
    printf 'replaced\t%s\toriginal/%s\n' "$destination" "$destination" >> "$record"
  else
    printf 'created\t%s\t-\n' "$destination" >> "$record"
  fi
  if [[ "$mode" == copy ]]; then
    cp -- "$source_real" "$target"
    cmp "$source_real" "$target" || bia_die "$BIA_HYBRID" "Copia divergente: $destination"
  else
    existing=""; [[ -f "$target" ]] && existing="$(cat "$target")"
    clean="$(printf '%s\n' "$existing" | sed '/# BEGIN B-IA managed/,/# END B-IA managed/d')"
    { printf '%s' "$clean"; [[ -z "$clean" ]] || printf '\n'; cat "$source_real"; } > "$target"
  fi
done < "$manifest"
printf 'Adopción completada: %s\n' "$record"
printf 'SHA-256 esperado para rollback: %s\n' "$(sha256sum "$record" | cut -d' ' -f1)"
