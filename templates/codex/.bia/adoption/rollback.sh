#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$here/../validators/common.sh"
consumer=""; record=""; expected_record_sha256=""
while (($#)); do
  case "$1" in
    --consumer) consumer="${2:-}"; shift 2;;
    --record) record="${2:-}"; shift 2;;
    --record-sha256) expected_record_sha256="${2:-}"; shift 2;;
    *) bia_die "$BIA_USAGE" "Opción inválida";;
  esac
done
[[ -n "$consumer" && -n "$record" && "$expected_record_sha256" =~ ^[0-9a-f]{64}$ ]] || bia_die "$BIA_USAGE" "Faltan argumentos o hash confiable"
consumer="$(realpath "$consumer")"
[[ -f "$record" && ! -L "$record" && "$(stat -c %h -- "$record" 2>/dev/null)" == 1 ]] || bia_die "$BIA_POLICY" "Registro inseguro"
record="$(realpath "$record")"; backup="$(dirname "$record")"
[[ "$record" == "$consumer/.bia-backup/"*/adoption-record.tsv ]] || bia_die "$BIA_POLICY" "Registro fuera del consumidor"
git -C "$consumer" rev-parse --show-toplevel >/dev/null 2>&1 || bia_die "$BIA_UNKNOWN" "Git no disponible"
record_snapshot="$(mktemp)"; trap 'rm -f "$record_snapshot"' EXIT
cp -- "$record" "$record_snapshot"
actual_record_sha256="$(sha256sum "$record_snapshot" | cut -d' ' -f1)"
[[ "$actual_record_sha256" == "$expected_record_sha256" ]] || bia_die "$BIA_POLICY" "Integridad del registro inválida"

safe_target() {
  local destination="$1" current="$consumer" component target
  case "$destination" in ''|/*|~*|..|../*|*/../*|*/..) bia_die "$BIA_POLICY" "Destino inseguro";; esac
  IFS='/' read -r -a components <<< "$destination"
  for component in "${components[@]:0:${#components[@]}-1}"; do
    current="$current/$component"
    if [[ -e "$current" || -L "$current" ]]; then
      [[ -d "$current" && ! -L "$current" ]] || bia_die "$BIA_POLICY" "Componente de destino inseguro"
    fi
  done
  target="$consumer/$destination"
  if [[ -e "$target" || -L "$target" ]]; then
    [[ ! -L "$target" ]] || bia_die "$BIA_POLICY" "Destino enlazado"
    if [[ -f "$target" ]]; then
      [[ "$(stat -c %h -- "$target" 2>/dev/null)" == 1 ]] || bia_die "$BIA_POLICY" "Destino con alias"
    else
      [[ -d "$target" ]] || bia_die "$BIA_POLICY" "Destino no regular"
    fi
  fi
  printf '%s\n' "$target"
}

trusted_saved_file() {
  local destination="$1" saved="$2" original_root candidate resolved current component
  [[ "$saved" == "original/$destination" ]] || bia_die "$BIA_POLICY" "Fuente de respaldo inesperada"
  original_root="$backup/original"
  [[ -d "$original_root" && ! -L "$original_root" ]] || bia_die "$BIA_POLICY" "Raíz de respaldo insegura"
  original_root="$(realpath "$original_root")"
  candidate="$backup/$saved"; current="$backup"
  IFS='/' read -r -a components <<< "$saved"
  for component in "${components[@]}"; do
    current="$current/$component"
    [[ ! -L "$current" ]] || bia_die "$BIA_POLICY" "Fuente de respaldo enlazada"
  done
  [[ -f "$candidate" && ! -L "$candidate" && "$(stat -c %h -- "$candidate" 2>/dev/null)" == 1 ]] || bia_die "$BIA_POLICY" "Fuente de respaldo insegura"
  resolved="$(realpath "$candidate")"
  [[ "$resolved" == "$original_root/"* ]] || bia_die "$BIA_POLICY" "Fuente de respaldo fuera de contención"
  printf '%s\n' "$resolved"
}

# Validate the immutable snapshot completely before changing the consumer.
while IFS=$'\t' read -r action destination saved; do
  [[ -n "$action" ]] || continue
  case "$action" in
    created|mkdir) [[ "$saved" == - ]] || bia_die "$BIA_POLICY" "Fuente inesperada"; safe_target "$destination" >/dev/null;;
    replaced) safe_target "$destination" >/dev/null; trusted_saved_file "$destination" "$saved" >/dev/null;;
    *) bia_die "$BIA_POLICY" "Acción desconocida";;
  esac
done < "$record_snapshot"

while IFS=$'\t' read -r action destination saved; do
  [[ -n "$action" ]] || continue
  target="$(safe_target "$destination")"
  case "$action" in
    created) rm -f -- "$target";;
    replaced) source_file="$(trusted_saved_file "$destination" "$saved")"; mkdir -p "$(dirname "$target")"; cp -- "$source_file" "$target";;
    mkdir) : ;;
  esac
done < "$record_snapshot"
while IFS=$'\t' read -r action destination saved; do
  [[ "$action" == mkdir ]] || continue
  directory="$(realpath -m "$consumer/$destination")"
  [[ "$directory" == "$consumer/"* ]] || bia_die "$BIA_POLICY" "Directorio fuera del consumidor"
  rmdir -- "$directory" 2>/dev/null || true
done < <(tac "$record_snapshot")
printf 'rollback_at=%s\nengram=preserved\n' "$(TZ=America/Mexico_City date --iso-8601=seconds)" > "$backup/rollback.log"
printf 'Rollback completado; Engram se conserva.\n'
