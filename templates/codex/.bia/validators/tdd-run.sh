#!/usr/bin/env bash
set -euo pipefail

[[ "$#" -eq 3 ]] || { printf 'Uso: tdd-run.sh TASK_ID PHASE TEST_ID\n' >&2; exit 2; }
task_id="$1" phase="$2" test_id="$3"
[[ "$task_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$ ]] || exit 2
[[ "$phase" =~ ^(RED|GREEN|REFACTOR)$ ]] || exit 2
[[ "$test_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$ ]] || exit 2

root="$(pwd -P)"
policy="$root/.bia/policies/tdd-tests.tsv"
[[ -f "$policy" && ! -L "$policy" ]] || exit 10
uid="$(id -u)"; [[ "$(stat -c %u "$policy")" == "$uid" && "$(stat -c %h "$policy")" == 1 ]] || exit 10
locator=""; matches=0
while IFS=$'\t' read -r candidate_id candidate_locator extra || [[ -n "$candidate_id$candidate_locator${extra:-}" ]]; do
  [[ -n "$candidate_id" && -n "$candidate_locator" && -z "${extra:-}" ]] || exit 13
  if [[ "$candidate_id" == "$test_id" ]]; then locator="$candidate_locator"; matches=$((matches + 1)); fi
done < "$policy"
[[ "$matches" -eq 1 && "$locator" != /* && "/$locator/" != *"/../"* && ! -L "$root/$locator" ]] || exit 13
test_file="$(realpath -e -- "$root/$locator" 2>/dev/null)" || exit 10
[[ "$test_file" == "$root/"* && -f "$test_file" && ! -L "$test_file" ]] || exit 10
[[ "$(stat -c %u "$test_file")" == "$uid" && "$(stat -c %h "$test_file")" == 1 ]] || exit 10
read -r test_hash _ < <(sha256sum "$test_file")

set +e
"$test_file"
test_code=$?
set -e
set +e
"$root/.bia/validators/tdd-event.sh" "$task_id" "$phase" "$test_id" "$test_code" "$locator" "$test_hash"
registrar_code=$?
set -e
if [[ "$registrar_code" -ne 0 ]]; then
  printf 'TDD event failed: test_id=%s test_exit=%s registrar_exit=%s\n' "$test_id" "$test_code" "$registrar_code" >&2
  exit "$registrar_code"
fi
exit "$test_code"

