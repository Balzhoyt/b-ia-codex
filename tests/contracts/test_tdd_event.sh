#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tool="$root/templates/codex/.bia/validators/tdd-event.sh"
policy_source="$root/templates/codex/.bia/policies/tdd-tests.tsv"
test -x "$tool"
test -s "$policy_source"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
consumer="$tmp/consumer"
mkdir -p "$consumer/.bia/validators" "$consumer/.bia/policies" "$consumer/tests/contracts"
cp "$tool" "$consumer/.bia/validators/tdd-event.sh"

cat > "$consumer/tests/contracts/test_alpha.sh" <<'EOF'
#!/usr/bin/env bash
printf 'must-not-run\n' >> "${SENTINEL:?}"
EOF
cat > "$consumer/tests/contracts/test_beta.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$consumer/tests/contracts/"*.sh
cat > "$consumer/.bia/policies/tdd-tests.tsv" <<'EOF'
test_alpha	tests/contracts/test_alpha.sh
test_beta	tests/contracts/test_beta.sh
EOF

alpha_hash="$(sha256sum "$consumer/tests/contracts/test_alpha.sh" | cut -d' ' -f1)"
beta_hash="$(sha256sum "$consumer/tests/contracts/test_beta.sh" | cut -d' ' -f1)"
register() { (cd "$consumer" && .bia/validators/tdd-event.sh "$@"); }
ledger="$consumer/.bia/evidence/tdd/events.jsonl"

# A valid post-test declaration records an internally generated UTC event without executing the test.
sentinel="$tmp/sentinel"
SENTINEL="$sentinel" register 4.4 RED test_alpha 7 tests/contracts/test_alpha.sh "$alpha_hash"
test ! -e "$sentinel"
test "$(wc -l < "$ledger")" -eq 1
event="$(cat "$ledger")"
jq -e 'keys == ["exit_code","phase","task_id","test_file","test_id","test_sha256","timestamp_utc"]' <<<"$event" >/dev/null
jq -e '.task_id=="4.4" and .phase=="RED" and .test_id=="test_alpha" and .exit_code==7 and .test_file=="tests/contracts/test_alpha.sh"' <<<"$event" >/dev/null
test "$(jq -r .test_sha256 <<<"$event")" = "$alpha_hash"
timestamp="$(jq -r .timestamp_utc <<<"$event")"
[[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
test "$(tail -c 1 "$ledger" | wc -l)" -eq 1
if grep -Eqi 'argv|stdout|stderr|diagnostic|base64|command_sanitized|capture_status|fifo|fd3' "$ledger"; then exit 1; fi

unchanged="$(sha256sum "$ledger")"
expect_rejected() {
  local expected="$1"; shift
  set +e; register "$@" >/dev/null 2>&1; local code=$?; set -e
  test "$code" -eq "$expected"
  test "$(sha256sum "$ledger")" = "$unchanged"
}
expect_rejected 2 4.4 BLUE test_alpha 0 tests/contracts/test_alpha.sh "$alpha_hash"
expect_rejected 2 4.4 GREEN test_alpha 1.5 tests/contracts/test_alpha.sh "$alpha_hash"
expect_rejected 13 4.4 GREEN unknown 0 tests/contracts/test_alpha.sh "$alpha_hash"
expect_rejected 13 4.4 GREEN test_alpha 0 tests/contracts/test_beta.sh "$beta_hash"
expect_rejected 12 4.4 GREEN test_alpha 0 tests/contracts/test_alpha.sh "$(printf '0%.0s' {1..64})"
expect_rejected 2 4.4 GREEN test_alpha 0 tests/contracts/test_alpha.sh "$alpha_hash" extra

cp "$consumer/.bia/policies/tdd-tests.tsv" "$tmp/policy.valid"
printf 'test_alias\ttests/contracts/test_alpha.sh\n' >> "$consumer/.bia/policies/tdd-tests.tsv"
expect_rejected 13 4.4 GREEN test_alias 0 tests/contracts/test_alpha.sh "$alpha_hash"
cp "$tmp/policy.valid" "$consumer/.bia/policies/tdd-tests.tsv"

# Test locators and ledgers reject symlinks and hardlinks without touching external bytes.
ln -s test_beta.sh "$consumer/tests/contracts/test_link.sh"
printf 'test_link\ttests/contracts/test_link.sh\n' >> "$consumer/.bia/policies/tdd-tests.tsv"
expect_rejected 10 4.4 GREEN test_link 0 tests/contracts/test_link.sh "$beta_hash"
cp "$consumer/tests/contracts/test_beta.sh" "$consumer/tests/contracts/test_hard.sh"
ln "$consumer/tests/contracts/test_hard.sh" "$tmp/test-hard.outside"
printf 'test_hard\ttests/contracts/test_hard.sh\n' >> "$consumer/.bia/policies/tdd-tests.tsv"
hard_hash="$(sha256sum "$consumer/tests/contracts/test_hard.sh" | cut -d' ' -f1)"
expect_rejected 10 4.4 GREEN test_hard 0 tests/contracts/test_hard.sh "$hard_hash"

for kind in symlink hardlink; do
  guarded="$tmp/$kind"; mkdir -p "$guarded/.bia/validators" "$guarded/.bia/policies" "$guarded/tests/contracts" "$guarded/.bia/evidence/tdd"
  cp "$tool" "$guarded/.bia/validators/tdd-event.sh"
  cp "$consumer/tests/contracts/test_beta.sh" "$guarded/tests/contracts/test_beta.sh"
  printf 'test_beta\ttests/contracts/test_beta.sh\n' > "$guarded/.bia/policies/tdd-tests.tsv"
  outside="$tmp/$kind.outside"; printf 'outside\n' > "$outside"; before="$(sha256sum "$outside")"
  if [[ "$kind" == symlink ]]; then ln -s "$outside" "$guarded/.bia/evidence/tdd/events.jsonl"; else ln "$outside" "$guarded/.bia/evidence/tdd/events.jsonl"; fi
  set +e; (cd "$guarded" && .bia/validators/tdd-event.sh 4.4 GREEN test_beta 0 tests/contracts/test_beta.sh "$beta_hash") >/dev/null 2>&1; code=$?; set -e
  test "$code" -eq 10; test "$(sha256sum "$outside")" = "$before"
done

# Complete-ledger verification is strict: final LF, exact schema/types, UTC, allowlist and live hash coherence.
cp "$ledger" "$tmp/valid-ledger"
(cd "$consumer" && .bia/validators/tdd-event.sh --verify)
# shellcheck disable=SC2206
invalid_lines=(
  '{"timestamp_utc":"2026-07-13T00:00:00Z","task_id":"4.4","phase":"RED","test_id":"test_alpha","exit_code":7,"test_file":"tests/contracts/test_alpha.sh"}'
  '{"timestamp_utc":"2026-02-30T00:00:00Z","task_id":"4.4","phase":"RED","test_id":"test_alpha","exit_code":7,"test_file":"tests/contracts/test_alpha.sh","test_sha256":"'$alpha_hash'"}'
  '{"timestamp_utc":"2026-07-13T00:00:00Z","task_id":"4.4","phase":"RED","test_id":"test_alpha","exit_code":1.5,"test_file":"tests/contracts/test_alpha.sh","test_sha256":"'$alpha_hash'"}'
  '{"timestamp_utc":"2026-07-13T00:00:00Z","task_id":"4.4","phase":"RED","test_id":"test_alpha","exit_code":7,"test_file":"tests/contracts/test_alpha.sh","test_sha256":"'$alpha_hash'","extra":true}'
)
for line in "${invalid_lines[@]}"; do
  printf '%s\n' "$line" > "$ledger"
  set +e; (cd "$consumer" && .bia/validators/tdd-event.sh --verify) >/dev/null 2>&1; code=$?; set -e
  test "$code" -eq 12
done
printf '%s' "$(cat "$tmp/valid-ledger")" > "$ledger"
set +e; (cd "$consumer" && .bia/validators/tdd-event.sh --verify) >/dev/null 2>&1; code=$?; set -e
test "$code" -eq 12
cp "$tmp/valid-ledger" "$ledger"

# Concurrent writers serialize; a live lock times out and no event is appended.
pids=()
for i in $(seq 1 8); do register "4.4.$i" GREEN test_beta 0 tests/contracts/test_beta.sh "$beta_hash" & pids+=("$!"); done
for pid in "${pids[@]}"; do wait "$pid"; done
test "$(wc -l < "$ledger")" -eq 9
jq -s -e 'length==9' "$ledger" >/dev/null
mkdir "$consumer/.bia/evidence/tdd/.lock"
printf '%s\n' "$$" > "$consumer/.bia/evidence/tdd/.lock/owner.pid"
set +e; register 4.4 GREEN test_beta 0 tests/contracts/test_beta.sh "$beta_hash" >/dev/null 2>&1; code=$?; set -e
test "$code" -eq 14; test "$(wc -l < "$ledger")" -eq 9
rm -rf "$consumer/.bia/evidence/tdd/.lock"

# Verify on an empty consumer never synthesizes history.
empty="$tmp/empty"; mkdir -p "$empty/.bia/validators" "$empty/.bia/policies"
cp "$tool" "$empty/.bia/validators/tdd-event.sh"; cp "$consumer/.bia/policies/tdd-tests.tsv" "$empty/.bia/policies/tdd-tests.tsv"
(cd "$empty" && .bia/validators/tdd-event.sh --verify)
test ! -e "$empty/.bia/evidence"

grep -q 'Evidencia TDD pasiva' "$root/templates/codex/docs/project/testing.md"
if grep -RqiE 'tdd-evidence|tdd-redaction|hash-only|capture_status|stdout_sha256|stderr_sha256' "$root/templates/codex/docs" "$root/templates/codex/.bia"; then exit 1; fi
