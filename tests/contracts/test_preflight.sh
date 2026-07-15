#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pre="$root/templates/codex/.bia/validators/preflight.sh"
# shellcheck disable=SC1091
source "$root/tests/contracts/lib/path_fixture.sh"
test -x "$pre"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
make_dependency_path "$tmp/bin-full" bash dirname jq
cp -a "$tmp/bin-full" "$tmp/bin-no-jq"; rm "$tmp/bin-no-jq/jq"
printf '%s\n' git codex gentle-ai engram jq > "$tmp/false-dependencies.txt"

assert_blocked() {
  local name="$1" payload="$2"
  printf '%s\n' "$payload" > "$tmp/$name.json"
  set +e; "$pre" --status-file "$tmp/$name.json" --expect spec >/dev/null 2>&1; local code=$?; set -e
  test "$code" -eq 11
}

PATH="$tmp/bin-full" "$pre" --status-file "$root/tests/fixtures/dispatcher/allowed.json" --expect spec
set +e
PATH="$tmp/bin-no-jq" BIA_DEPENDENCY_FIXTURE="$tmp/false-dependencies.txt" "$pre" --status-file "$root/tests/fixtures/dispatcher/allowed.json" --expect spec >/dev/null 2>&1
missing_jq=$?
set -e
test "$missing_jq" -eq 3
assert_blocked truncated '{"blockedReasons":[],"nextRecommended":"spec"'
assert_blocked trailing '{"blockedReasons":[],"nextRecommended":"spec"} basura'
assert_blocked nested-conflict '{"blockedReasons":["real"],"nextRecommended":"apply","nested":{"blockedReasons":[],"nextRecommended":"spec"}}'
assert_blocked missing-blockers '{"nextRecommended":"spec"}'
assert_blocked missing-next '{"blockedReasons":[]}'
assert_blocked null-blockers '{"blockedReasons":null,"nextRecommended":"spec"}'
assert_blocked wrong-blockers '{"blockedReasons":"ninguno","nextRecommended":"spec"}'
assert_blocked wrong-blocker-item '{"blockedReasons":[7],"nextRecommended":"spec"}'
assert_blocked null-next '{"blockedReasons":[],"nextRecommended":null}'
assert_blocked wrong-next '{"blockedReasons":[],"nextRecommended":7}'
assert_blocked exact-mismatch '{"blockedReasons":[],"nextRecommended":"spec-extra"}'
set +e; printf '%s\n' '{"blockedReasons":[],"nextRecommended":"arbitrary"}' > "$tmp/invalid-recommendation.json"; "$pre" --status-file "$tmp/invalid-recommendation.json" >/dev/null 2>&1; invalid_recommendation=$?; set -e
test "$invalid_recommendation" -eq 11
printf '%s\n' '{"blockedReasons":[],"nextRecommended":"resolve-blockers"}' > "$tmp/resolve-blockers.json"
set +e; "$pre" --status-file "$tmp/resolve-blockers.json" >/dev/null 2>&1; resolve_without_expect=$?; "$pre" --status-file "$tmp/resolve-blockers.json" --expect resolve-blockers >/dev/null 2>&1; resolve_with_expect=$?; set -e
test "$resolve_without_expect" -eq 11
test "$resolve_with_expect" -eq 11

set +e; "$pre" --status-file "$root/tests/fixtures/dispatcher/unknown.json" --read-only >/dev/null 2>&1; unknown=$?; set -e
test "$unknown" -eq 3
