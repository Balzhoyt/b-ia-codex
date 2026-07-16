#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
adopt="$root/templates/codex/.bia/adoption/adopt.sh"
rollback="$root/templates/codex/.bia/adoption/rollback.sh"
manifest="$root/templates/codex/.bia/adoption/manifest.tsv"
# shellcheck source=/dev/null
source "$root/tests/contracts/lib/path_fixture.sh"
test -x "$adopt"; test -x "$rollback"; test -s "$manifest"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
make_dependency_path "$tmp/bin-full" \
  bash env dirname realpath git jq mktemp find sed sort awk uniq comm tr \
  date sleep seq mkdir cp cmp cat head tail rm sha256sum cut grep wc tac rmdir chmod basename \
  sync tee ln mkfifo perl stat id mv
for dependency in codex gentle-ai engram; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin-full/$dependency"
  chmod +x "$tmp/bin-full/$dependency"
done
run_adopt() { PATH="$tmp/bin-full" "$adopt" "$@"; }
printf '%s\n' git codex gentle-ai engram jq > "$tmp/false-dependencies.txt"
consumer="$tmp/consumer"; mkdir -p "$consumer/.agents" "$consumer/keep-empty"; git -C "$consumer" init -q
printf 'original\n' > "$consumer/AGENTS.md"
before="$(sha256sum "$consumer/AGENTS.md" | cut -d' ' -f1)"
PATH="$tmp/bin-full" "$adopt" --root "$root" --consumer "$consumer" --manifest "$manifest" --dry-run
for dependency in jq codex gentle-ai engram git; do
  cp -a "$tmp/bin-full" "$tmp/bin-no-$dependency"; rm "$tmp/bin-no-$dependency/$dependency"
  set +e
  PATH="$tmp/bin-no-$dependency" BIA_DEPENDENCY_FIXTURE="$tmp/false-dependencies.txt" "$adopt" --root "$root" --consumer "$consumer" --manifest "$manifest" --dry-run >/dev/null 2>&1
  missing=$?
  set -e
  test "$missing" -eq 3
done
grep -Eq '(^|[^[:alnum:]])jq([^[:alnum:]]|$)' "$root/templates/codex/docs/project/development.md"
test "$(sha256sum "$consumer/AGENTS.md" | cut -d' ' -f1)" = "$before"
adoption_output="$(run_adopt --root "$root" --consumer "$consumer" --manifest "$manifest")"
printf '%s\n' "$adoption_output"
cmp "$root/templates/codex/AGENTS.md" "$consumer/AGENTS.md"
cmp "$root/templates/codex/.agents/skills/bia-explorar-idea/SKILL.md" "$consumer/.agents/skills/bia-explorar-idea/SKILL.md"
test ! -e "$consumer/tests/contracts"
test -x "$consumer/.bia/validators/tdd-run.sh"
test -x "$consumer/.bia/validators/tdd-self-check.sh"
grep -Fqx $'bia_tdd_event_self_check\t.bia/validators/tdd-self-check.sh' "$consumer/.bia/policies/tdd-tests.tsv"
(
  cd "$consumer"
  .bia/validators/tdd-run.sh adoption GREEN bia_tdd_event_self_check
  .bia/validators/tdd-event.sh --verify
)
consumer_event="$consumer/.bia/evidence/tdd/events.jsonl"
test "$(jq -r .test_id "$consumer_event")" = bia_tdd_event_self_check
test "$(jq -r .exit_code "$consumer_event")" -eq 0
test "$(jq -r .test_file "$consumer_event")" = .bia/validators/tdd-self-check.sh
test "$(jq -r .test_sha256 "$consumer_event")" = "$(sha256sum "$consumer/.bia/validators/tdd-self-check.sh" | cut -d' ' -f1)"
grep -q 'tests/contracts/run.sh' "$root/openspec/config.yaml"
record="$(find "$consumer/.bia-backup" -name adoption-record.tsv | head -n1)"; test -s "$record"
expected_record_sha256="$(sha256sum "$record" | cut -d' ' -f1)"
grep -Fq "SHA-256 esperado para rollback: $expected_record_sha256" <<< "$adoption_output"
"$rollback" --consumer "$consumer" --record "$record" --record-sha256 "$expected_record_sha256"
test "$(cat "$consumer/AGENTS.md")" = original
test ! -e "$consumer/.agents/skills/bia-explorar-idea/SKILL.md"
test -d "$consumer/.agents"; test ! -e "$consumer/.agents/skills"; test -d "$consumer/keep-empty"
test -s "$(dirname "$record")/rollback.log"

# A forged but syntactically valid record must not delete consumer-local state.
forged="$consumer/.bia-backup/forged"; mkdir -p "$forged"
printf 'valuable\n' > "$consumer/valuable"
printf 'created\tvaluable\t-\n' > "$forged/adoption-record.tsv"
set +e; "$rollback" --consumer "$consumer" --record "$forged/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; forged_code=$?; set -e
test "$forged_code" -eq 10; test "$(cat "$consumer/valuable")" = valuable
mkdir "$consumer/valuable-dir"
printf 'mkdir\tvaluable-dir\t-\n' > "$forged/adoption-record.tsv"
set +e; "$rollback" --consumer "$consumer" --record "$forged/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; forged_code=$?; set -e
test "$forged_code" -eq 10; test -d "$consumer/valuable-dir"

cp "$record" "$forged/adoption-record.tsv"; printf 'created\tvaluable\t-\n' >> "$forged/adoption-record.tsv"
set +e; "$rollback" --consumer "$consumer" --record "$forged/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; forged_code=$?; set -e
test "$forged_code" -eq 10; test "$(cat "$consumer/valuable")" = valuable
tac "$record" > "$forged/adoption-record.tsv"
set +e; "$rollback" --consumer "$consumer" --record "$forged/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; forged_code=$?; set -e
test "$forged_code" -eq 10; test "$(cat "$consumer/valuable")" = valuable
set +e; "$rollback" --consumer "$consumer" --record "$record" >/dev/null 2>&1; missing_hash_code=$?; set -e
test "$missing_hash_code" -eq 2; test "$(cat "$consumer/valuable")" = valuable

# Rollback records are attacker-editable input: saved sources must remain trusted backup files.
rollback_attack="$consumer/.bia-backup/tampered"; mkdir -p "$rollback_attack/original"
printf 'safe\n' > "$consumer/restore-target"
printf 'replaced\trestore-target\t../../../../../../etc/hostname\n' > "$rollback_attack/adoption-record.tsv"
set +e; "$rollback" --consumer "$consumer" --record "$rollback_attack/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; rollback_code=$?; set -e
test "$rollback_code" -eq 10; test "$(cat "$consumer/restore-target")" = safe

printf 'trusted\n' > "$rollback_attack/original/source"
for kind in symlink hardlink directory; do
  rm -f "$rollback_attack/original/alias"
  if [[ "$kind" == symlink ]]; then
    ln -s source "$rollback_attack/original/alias"
  elif [[ "$kind" == hardlink ]]; then
    ln "$rollback_attack/original/source" "$rollback_attack/original/alias"
  else
    mkdir "$rollback_attack/original/alias"
  fi
  printf 'replaced\trestore-target\toriginal/alias\n' > "$rollback_attack/adoption-record.tsv"
  set +e; "$rollback" --consumer "$consumer" --record "$rollback_attack/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; rollback_code=$?; set -e
  test "$rollback_code" -eq 10; test "$(cat "$consumer/restore-target")" = safe
  [[ "$kind" != directory ]] || rmdir "$rollback_attack/original/alias"
done

printf 'trusted\n' > "$rollback_attack/original/restore-target"
for kind in symlink hardlink; do
  outside="$tmp/rollback-target-$kind.outside"; printf 'outside\n' > "$outside"
  rm -f "$consumer/restore-target"
  if [[ "$kind" == symlink ]]; then ln -s "$outside" "$consumer/restore-target"; else ln "$outside" "$consumer/restore-target"; fi
  printf 'replaced\trestore-target\toriginal/restore-target\n' > "$rollback_attack/adoption-record.tsv"
  set +e; "$rollback" --consumer "$consumer" --record "$rollback_attack/adoption-record.tsv" --record-sha256 "$expected_record_sha256" >/dev/null 2>&1; rollback_code=$?; set -e
  test "$rollback_code" -eq 10; test "$(cat "$outside")" = outside
done
rm -f "$consumer/restore-target"

# Adoption must never follow an existing final-component alias.
for kind in symlink hardlink; do
  alias_consumer="$tmp/alias-$kind"; mkdir -p "$alias_consumer"; git -C "$alias_consumer" init -q
  outside="$tmp/alias-$kind.outside"; printf 'outside\n' > "$outside"
  if [[ "$kind" == symlink ]]; then ln -s "$outside" "$alias_consumer/AGENTS.md"; else ln "$outside" "$alias_consumer/AGENTS.md"; fi
  set +e; run_adopt --root "$root" --consumer "$alias_consumer" --manifest "$manifest" >/dev/null 2>&1; alias_code=$?; set -e
  test "$alias_code" -eq 10; test "$(cat "$outside")" = outside
done

bad="$tmp/bad.tsv"
printf 'canonical-source\ttemplates/codex/AGENTS.md\t../escape.md\tcopy\n' > "$bad"
set +e; run_adopt --root "$root" --consumer "$consumer" --manifest "$bad"; code=$?; set -e
test "$code" -eq 10; test ! -e "$tmp/escape.md"

incomplete="$tmp/incomplete.tsv"; grep -v 'templates/codex/AGENTS.md' "$manifest" > "$incomplete"
set +e; run_adopt --root "$root" --consumer "$consumer" --manifest "$incomplete" --dry-run; incomplete_code=$?; set -e
test "$incomplete_code" -eq 10
extra="$tmp/extra.tsv"; cat "$manifest" > "$extra"; printf 'canonical-source\ttemplates/codex/AGENTS.md\tSECOND.md\tcopy\n' >> "$extra"
set +e; run_adopt --root "$root" --consumer "$consumer" --manifest "$extra" --dry-run; extra_code=$?; set -e
test "$extra_code" -eq 10
duplicate_destination="$tmp/duplicate-destination.tsv"
awk -F '\t' 'BEGIN{OFS="\t"} /^#/ {print; next} ++n==1 {first=$3; print; next} n==2 {$3=first} {print}' "$manifest" > "$duplicate_destination"
set +e; run_adopt --root "$root" --consumer "$consumer" --manifest "$duplicate_destination" --dry-run; duplicate_destination_code=$?; set -e
test "$duplicate_destination_code" -eq 10
