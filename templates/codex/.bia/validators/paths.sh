#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=templates/codex/.bia/validators/common.sh
source "$here/common.sh"

(($# == 4)) || bia_die "$BIA_USAGE" "Uso: paths.sh canonical-source SOURCE DEST CONSUMER"
class="$1"; source_path="$2"; destination="$3"; consumer="$4"
[[ "$class" == canonical-source ]] || bia_die "$BIA_POLICY" "Clase inválida: $class"
consumer_real="$(realpath -m "$consumer")"
[[ "$source_path" == templates/codex/* ]] || bia_die "$BIA_POLICY" "Fuente fuera de templates/codex"
source_root="$(realpath -m "$consumer/templates/codex")"
[[ "$source_root" == "$consumer_real"/* ]] || bia_die "$BIA_POLICY" "Raíz de fuente fuera del consumidor"
source_real="$(realpath -m "$consumer/$source_path")"
[[ "$source_real" == "$source_root"/* ]] || bia_die "$BIA_POLICY" "Fuente fuera de templates/codex"
case "$destination" in
  /*|~*|*"\$HOME"*|*'..'*|.codex/*) bia_die "$BIA_POLICY" "Destino no local: $destination" ;;
esac
[[ "$destination" != *"~/.codex/skills"* ]] || bia_die "$BIA_POLICY" "Destino global prohibido"
dest_real="$(realpath -m "$consumer/$destination")"
[[ "$dest_real" == "$consumer_real"/* ]] || bia_die "$BIA_POLICY" "El destino escapa del consumidor"

# Existing symlink components must also remain contained.
probe="$consumer"
IFS='/' read -r -a parts <<< "$destination"
for part in "${parts[@]}"; do
  probe="$probe/$part"
  if [[ -L "$probe" ]]; then
    link_real="$(realpath "$probe")" || bia_die "$BIA_POLICY" "Symlink de destino no resoluble"
    [[ "$link_real" == "$consumer_real"/* ]] || bia_die "$BIA_POLICY" "Symlink fuera del consumidor"
  fi
done
exit "$BIA_OK"
