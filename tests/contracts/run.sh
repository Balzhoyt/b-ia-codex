#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
contract_dir="${BIA_CONTRACT_DIR:-$root/tests/contracts}"
workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT
export BIA_TEST_TMP="$workspace"

count=0
for test_file in "$contract_dir"/test_*.sh; do
  [[ -f "$test_file" && -r "$test_file" ]] || { printf 'ERROR: unreadable contract test: %s\n' "$test_file" >&2; exit 1; }
  printf '==> %s\n' "$(basename "$test_file")"
  set +e
  bash "$test_file"
  test_code=$?
  set -e
  [[ "$test_code" -eq 0 ]] || exit "$test_code"
  count=$((count + 1))
done
printf 'PASS: %d contract test files\n' "$count"
