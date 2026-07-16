#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
hybrid="$root/templates/codex/.bia/validators/hybrid.sh"
canon="$root/templates/codex/.bia/validators/lib/canonicalize.sh"
test -x "$hybrid"; test -x "$canon"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
expect_exit() {
  local expected="$1"; shift
  set +e
  "$@" >"$tmp/stdout" 2>"$tmp/stderr"
  local actual=$?
  set -e
  test "$actual" -eq "$expected"
  test ! -s "$tmp/stdout"
}
printf '# Uno\r\n\r\nTexto   \r\n\r\n' > "$tmp/a.md"
printf '# Uno\n\nTexto\n' > "$tmp/b.md"
"$hybrid" compare "$tmp/a.md" "$tmp/b.md"
printf '# Especificación\n' > "$tmp/content.md"
"$hybrid" validate-engram "$root/tests/fixtures/engram/single.json" sdd/demo/spec "$tmp/content.md"
for fixture in duplicate wrong-topic tampered mixed-objects; do
  expect_exit 12 "$hybrid" validate-engram "$root/tests/fixtures/engram/$fixture.json" sdd/demo/spec "$tmp/content.md"
done

printf '{broken' > "$tmp/malformed.json"
expect_exit 12 "$hybrid" validate-engram "$tmp/malformed.json" sdd/demo/spec "$tmp/content.md"
printf '{"results":{}}\n' > "$tmp/not-array.json"
expect_exit 12 "$hybrid" validate-engram "$tmp/not-array.json" sdd/demo/spec "$tmp/content.md"
for junk in 'true' '[]' '"junk"' 'null'; do
  printf '{"results":[%s]}\n' "$junk" > "$tmp/junk.json"
  expect_exit 12 "$hybrid" validate-engram "$tmp/junk.json" sdd/demo/spec "$tmp/content.md"
done
sed 's/"id":1/"id":true/' "$root/tests/fixtures/engram/single.json" > "$tmp/bad-id.json"
expect_exit 12 "$hybrid" validate-engram "$tmp/bad-id.json" sdd/demo/spec "$tmp/content.md"

# Canonical hashing accepts harmless line-ending/space differences, but not aliases.
ln -s "$tmp/content.md" "$tmp/content-link.md"
expect_exit 10 "$hybrid" compare "$tmp/content-link.md" "$tmp/content.md"
ln "$tmp/content.md" "$tmp/content-hardlink.md"
expect_exit 10 "$hybrid" compare "$tmp/content-hardlink.md" "$tmp/content.md"
rm "$tmp/content-hardlink.md"

trusted="$tmp/trusted"; mkdir -p "$trusted/.bia/tmp"
printf 'anterior\n' > "$tmp/open.md"; printf 'parcial\n' > "$trusted/.bia/tmp/artifact.pending"
"$hybrid" recover "$trusted" "$tmp/open.md" .bia/tmp/artifact.pending
cmp "$tmp/open.md" "$trusted/.bia/tmp/artifact.pending"
"$hybrid" stage "$trusted" "$tmp/open.md" .bia/tmp/staged.pending
cmp "$tmp/open.md" "$trusted/.bia/tmp/staged.pending"
expect_exit 10 "$hybrid" stage "$trusted" "$tmp/open.md" .bia/tmp/staged.pending
expect_exit 10 "$hybrid" recover "$trusted" "$tmp/open.md" .bia/tmp/missing.pending
expect_exit 10 "$hybrid" stage "$trusted" "$tmp/open.md" /tmp/absolute.pending
expect_exit 10 "$hybrid" stage "$trusted" "$tmp/open.md" ../escape.pending
mkdir "$trusted/real-dir"; ln -s "$trusted/real-dir" "$trusted/linked-dir"
expect_exit 10 "$hybrid" stage "$trusted" "$tmp/open.md" linked-dir/escape.pending
ln -s "$trusted" "$tmp/trusted-link"
expect_exit 10 "$hybrid" stage "$tmp/trusted-link" "$tmp/open.md" linked-root.pending
expect_exit 2 "$hybrid" stage "$trusted" "$tmp/open.md"
