#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
validator="$root/templates/codex/.bia/validators/artifact.sh"
fixtures="$root/tests/fixtures/artifacts"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

expect_code() {
  local expected="$1"
  shift
  set +e
  "$@" >/dev/null 2>&1
  local actual=$?
  set -e
  test "$actual" -eq "$expected" || {
    printf 'expected exit %s, got %s: %s\n' "$expected" "$actual" "$*" >&2
    return 1
  }
}

test -x "$validator"
"$validator" "$fixtures/valid.md" --section Evidencia --base "$root"

for file in invalid.md missing-reference.md; do
  expect_code 10 "$validator" "$fixtures/$file" --section Evidencia --base "$root"
done

cat >"$tmp/english.md" <<'EOF'
# Model

## Evidence

The model validates documentation.
EOF
expect_code 10 "$validator" "$tmp/english.md" --base "$tmp"

cat >"$tmp/missing-section.md" <<'EOF'
# Artefacto válido

Contenido de trabajo verificable.
EOF
expect_code 10 "$validator" "$tmp/missing-section.md" --section Evidencia --base "$tmp"

cat >"$tmp/absolute-reference.md" <<EOF
# Artefacto válido

## Evidencia

Consulte [archivo]($root/README.md).
EOF
expect_code 10 "$validator" "$tmp/absolute-reference.md" --base "$tmp"

mkdir "$tmp/base" "$tmp/outside"
printf '# Destino\n' >"$tmp/outside/target.md"
cat >"$tmp/base/traversal.md" <<'EOF'
# Artefacto válido

## Evidencia

Consulte [archivo](../outside/target.md).
EOF
expect_code 10 "$validator" "$tmp/base/traversal.md" --base "$tmp/base"

ln -s ../outside/target.md "$tmp/base/link.md"
sed 's#../outside/target.md#link.md#' "$tmp/base/traversal.md" >"$tmp/base/symlink-reference.md"
expect_code 10 "$validator" "$tmp/base/symlink-reference.md" --base "$tmp/base"

ln -s "$fixtures/valid.md" "$tmp/artifact-link.md"
expect_code 10 "$validator" "$tmp/artifact-link.md" --base "$root"

expect_code 2 "$validator" "$fixtures/valid.md" --section
expect_code 2 "$validator" "$fixtures/valid.md" --base
expect_code 2 "$validator" "$fixtures/valid.md" --base "$root" --base "$root"
expect_code 2 "$validator" "$fixtures/valid.md" --section Evidencia --section Evidencia

cat >"$tmp/fenced-section.md" <<'EOF'
# Artefacto válido

El trabajo requiere evidencia verificable.

```markdown
## Evidencia
```
EOF
expect_code 10 "$validator" "$tmp/fenced-section.md" --section Evidencia --base "$tmp"

cat >"$tmp/fenced-link.md" <<'EOF'
# Artefacto válido

## Evidencia

El documento contiene la evidencia del trabajo y se considera verificable.

```markdown
[ejemplo roto](no-existe.md)
```
EOF
"$validator" "$tmp/fenced-link.md" --section Evidencia --base "$tmp"
# Literal Markdown fence, not shell expansion.
# shellcheck disable=SC2016
sed 's/^```/   ```/' "$tmp/fenced-link.md" >"$tmp/indented-fenced-link.md"
"$validator" "$tmp/indented-fenced-link.md" --section Evidencia --base "$tmp"

cat >"$tmp/invalid-fence-close.md" <<'EOF'
# Artefacto válido

El documento contiene la evidencia del trabajo y se considera verificable.

````markdown
```not-close
[enlace](no-existe.md)
````
EOF
"$validator" "$tmp/invalid-fence-close.md" --base "$tmp"

cat >"$tmp/reference-style.md" <<'EOF'
# Artefacto válido

## Evidencia

El documento contiene la [evidencia][prueba] del trabajo y se considera verificable.

[prueba]: valid.md "Documento válido"
EOF
cp "$fixtures/valid.md" "$tmp/valid.md"
"$validator" "$tmp/reference-style.md" --section Evidencia --base "$tmp"
sed 's#valid.md#no-existe.md#' "$tmp/reference-style.md" >"$tmp/reference-style-broken.md"
expect_code 10 "$validator" "$tmp/reference-style-broken.md" --base "$tmp"

sed 's/\[evidencia\]\[prueba\]/[prueba][]/' "$tmp/reference-style.md" >"$tmp/collapsed-reference.md"
"$validator" "$tmp/collapsed-reference.md" --section Evidencia --base "$tmp"
sed '/^\[prueba\]:/d' "$tmp/collapsed-reference.md" >"$tmp/collapsed-reference-missing.md"
expect_code 10 "$validator" "$tmp/collapsed-reference-missing.md" --base "$tmp"

sed 's/\[evidencia\]\[prueba\]/[prueba]/' "$tmp/reference-style.md" >"$tmp/shortcut-reference.md"
expect_code 10 "$validator" "$tmp/shortcut-reference.md" --base "$tmp"

cat >"$tmp/inline-title.md" <<'EOF'
# Artefacto válido

## Evidencia

El documento contiene la [evidencia](valid.md "Documento válido") del trabajo
y una [fuente](HTTPS://example.com/recurso) que se considera verificable.
EOF
"$validator" "$tmp/inline-title.md" --section Evidencia --base "$tmp"

cp "$fixtures/valid.md" "$tmp/a_(b).md"
sed 's#valid.md "Documento válido"#a_(b).md "Documento válido"#' "$tmp/inline-title.md" >"$tmp/balanced-parentheses.md"
"$validator" "$tmp/balanced-parentheses.md" --section Evidencia --base "$tmp"

cat >"$tmp/malformed-link.md" <<'EOF'
# Artefacto válido

## Evidencia

El trabajo contiene [evidencia](valid.md sin cierre.
EOF
expect_code 10 "$validator" "$tmp/malformed-link.md" --base "$tmp"
sed 's#valid.md sin cierre#valid.md "título sin cierre)#' "$tmp/malformed-link.md" >"$tmp/malformed-title.md"
expect_code 10 "$validator" "$tmp/malformed-title.md" --base "$tmp"

sed 's#\[evidencia\](valid.md sin cierre.#\[evidencia\][ausente].#' "$tmp/malformed-link.md" >"$tmp/unresolved-reference.md"
expect_code 10 "$validator" "$tmp/unresolved-reference.md" --base "$tmp"

cat >"$tmp/weak-spanish.md" <<'EOF'
# Model

## Evidence

The model is valid para production.
EOF
expect_code 10 "$validator" "$tmp/weak-spanish.md" --base "$tmp"

cat >"$tmp/spanish-headings-only.md" <<'EOF'
# Artefacto válido

## Evidencia verificable

The model contains complete production documentation.
EOF
expect_code 10 "$validator" "$tmp/spanish-headings-only.md" --base "$tmp"

for sample in "artefacto evidencia" "trabajoid evidenciable"; do
  cat >"$tmp/english-domain.md" <<EOF
# Report

## Evidence

The English prose mentions $sample but remains entirely English.
EOF
  expect_code 10 "$validator" "$tmp/english-domain.md" --base "$tmp"
done

cat >"$tmp/spanish-prose.md" <<'EOF'
# Informe

## Evidencia

Este documento describe el trabajo realizado y contiene la evidencia de una referencia verificable.
EOF
"$validator" "$tmp/spanish-prose.md" --section Evidencia --base "$tmp"

mkdir "$tmp/base/directory"
sed 's#../outside/target.md#directory#' "$tmp/base/traversal.md" >"$tmp/base/directory-reference.md"
expect_code 10 "$validator" "$tmp/base/directory-reference.md" --base "$tmp/base"

cp "$fixtures/valid.md" "$tmp/original-artifact.md"
ln "$tmp/original-artifact.md" "$tmp/hardlink-artifact.md"
expect_code 10 "$validator" "$tmp/hardlink-artifact.md" --base "$tmp"

cp "$fixtures/valid.md" "$tmp/base/original.md"
ln "$tmp/base/original.md" "$tmp/base/alias.md"
sed 's#../outside/target.md#alias.md#' "$tmp/base/traversal.md" >"$tmp/base/hardlink-reference.md"
expect_code 10 "$validator" "$tmp/base/hardlink-reference.md" --base "$tmp/base"
