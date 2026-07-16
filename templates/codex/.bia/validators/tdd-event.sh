#!/usr/bin/env bash
set -euo pipefail

BIA_USAGE=2 BIA_UNKNOWN=3 BIA_PATH=10 BIA_LEDGER=12 BIA_ALLOWLIST=13 BIA_TIMEOUT=14
die() { local code="$1"; shift; printf 'B-IA TDD event: %s\n' "$*" >&2; exit "$code"; }
available() { command -v "$1" >/dev/null 2>&1; }
owned_regular() {
  local path="$1"
  [[ -f "$path" && ! -L "$path" ]] || return 1
  [[ "$(stat -c %u "$path" 2>/dev/null)" == "$uid" ]] || return 1
  [[ "$(stat -c %h "$path" 2>/dev/null)" == 1 ]]
}
owned_directory() {
  local path="$1"
  [[ -d "$path" && ! -L "$path" ]] || return 1
  [[ "$(stat -c %u "$path" 2>/dev/null)" == "$uid" ]]
}
valid_id() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$ ]]; }
valid_hash() { [[ "$1" =~ ^[0-9a-f]{64}$ ]]; }
valid_locator() {
  [[ "$1" =~ ^[A-Za-z0-9._/-]+$ && "$1" != /* && "$1" != *"//"* ]]
  [[ "/$1/" != *"/../"* && "/$1/" != *"/./"* ]]
}

for dependency in jq sha256sum stat id date realpath sync sleep; do
  available "$dependency" || die "$BIA_UNKNOWN" "Dependencia ausente: $dependency"
done
root="$(pwd -P)"
uid="$(id -u)"
policy="$root/.bia/policies/tdd-tests.tsv"
base="$root/.bia/evidence/tdd"
ledger="$base/events.jsonl"
lock="$base/.lock"
lock_acquired=false

safe_existing_directories() {
  local path
  for path in "$root/.bia" "$root/.bia/evidence" "$base"; do
    [[ ! -e "$path" && ! -L "$path" ]] || owned_directory "$path" || return 1
  done
}

resolve_allowed_test() {
  local wanted_id="$1" wanted_locator="$2" line_id line_locator found=0 candidate
  local -A seen_ids=() seen_locators=()
  owned_regular "$policy" || return "$BIA_PATH"
  while IFS=$'\t' read -r line_id line_locator extra || [[ -n "$line_id$line_locator${extra:-}" ]]; do
    [[ -n "$line_id" && -n "$line_locator" && -z "${extra:-}" ]] || return "$BIA_ALLOWLIST"
    valid_id "$line_id" && valid_locator "$line_locator" || return "$BIA_ALLOWLIST"
    [[ -z "${seen_ids[$line_id]:-}" && -z "${seen_locators[$line_locator]:-}" ]] || return "$BIA_ALLOWLIST"
    seen_ids["$line_id"]=1; seen_locators["$line_locator"]=1
    if [[ "$line_id" == "$wanted_id" ]]; then
      ((found += 1)); [[ "$line_locator" == "$wanted_locator" ]] || return "$BIA_ALLOWLIST"
    fi
  done < "$policy"
  [[ "$found" -eq 1 ]] || return "$BIA_ALLOWLIST"
  [[ ! -L "$root/$wanted_locator" ]] || return "$BIA_PATH"
  candidate="$(realpath -e -- "$root/$wanted_locator" 2>/dev/null)" || return "$BIA_PATH"
  [[ "$candidate" == "$root/"* ]] || return "$BIA_PATH"
  owned_regular "$candidate" || return "$BIA_PATH"
  resolved_test="$candidate"
}

validate_timestamp() {
  local value="$1" normalized
  [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || return 1
  normalized="$(date -u -d "$value" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" || return 1
  [[ "$normalized" == "$value" ]]
}

validate_event() {
  local line="$1" fields timestamp task phase test_id exit_code test_file test_hash actual_hash
  jq -e '
    (keys == ["exit_code","phase","task_id","test_file","test_id","test_sha256","timestamp_utc"]) and
    (.timestamp_utc|type)=="string" and (.task_id|type)=="string" and
    (.phase|type)=="string" and (.test_id|type)=="string" and
    (.exit_code|type)=="number" and (.exit_code == (.exit_code|floor)) and
    (.exit_code >= 0 and .exit_code <= 255) and (.test_file|type)=="string" and
    (.test_sha256|type)=="string"
  ' >/dev/null 2>&1 <<<"$line" || return 1
  fields="$(jq -r '[.timestamp_utc,.task_id,.phase,.test_id,(.exit_code|tostring),.test_file,.test_sha256]|@tsv' <<<"$line")" || return 1
  IFS=$'\t' read -r timestamp task phase test_id exit_code test_file test_hash <<<"$fields"
  validate_timestamp "$timestamp" && valid_id "$task" && [[ "$phase" =~ ^(RED|GREEN|REFACTOR)$ ]] || return 1
  valid_id "$test_id" && valid_hash "$test_hash" || return 1
  resolve_allowed_test "$test_id" "$test_file" || return 1
  actual_hash="$(sha256sum "$resolved_test" | cut -d' ' -f1)" || return 1
  [[ "$actual_hash" == "$test_hash" ]]
}

validate_ledger() {
  local line
  [[ ! -e "$ledger" && ! -L "$ledger" ]] && return 0
  owned_regular "$ledger" || return "$BIA_PATH"
  [[ ! -s "$ledger" || "$(tail -c 1 "$ledger" | wc -l)" -eq 1 ]] || return "$BIA_LEDGER"
  while IFS= read -r line; do
    [[ -n "$line" ]] && validate_event "$line" || return "$BIA_LEDGER"
  done < "$ledger"
}

if [[ "${1:-}" == --verify ]]; then
  [[ "$#" -eq 1 ]] || die "$BIA_USAGE" "Uso: tdd-event.sh --verify"
  safe_existing_directories || die "$BIA_PATH" "Ruta de evidencia insegura"
  [[ ! -e "$ledger" && ! -L "$ledger" ]] && exit 0
  validate_ledger || { code=$?; die "$code" "Ledger inválido"; }
  exit 0
fi

[[ "$#" -eq 6 ]] || die "$BIA_USAGE" "Uso: tdd-event.sh TASK_ID PHASE TEST_ID EXIT_CODE TEST_FILE TEST_SHA256"
task_id="$1" phase="$2" test_id="$3" exit_code="$4" test_file="$5" test_sha256="$6"
if ! valid_id "$task_id" || [[ ! "$phase" =~ ^(RED|GREEN|REFACTOR)$ ]] || ! valid_id "$test_id"; then die "$BIA_USAGE" "Campos inválidos"; fi
if [[ ! "$exit_code" =~ ^(0|[1-9][0-9]{0,2})$ ]] || ((exit_code > 255)); then die "$BIA_USAGE" "exit_code inválido"; fi
if ! valid_locator "$test_file" || ! valid_hash "$test_sha256"; then die "$BIA_USAGE" "Locator o hash inválido"; fi
resolve_allowed_test "$test_id" "$test_file" || { code=$?; die "$code" "Test no permitido o inseguro"; }
actual_hash="$(sha256sum "$resolved_test" | cut -d' ' -f1)" || die "$BIA_LEDGER" "No se pudo calcular el hash"
[[ "$actual_hash" == "$test_sha256" ]] || die "$BIA_LEDGER" "Hash divergente"
safe_existing_directories || die "$BIA_PATH" "Ruta de evidencia insegura"
mkdir -p "$base" || die "$BIA_PATH" "No se pudo crear evidencia"
safe_existing_directories || die "$BIA_PATH" "Ruta de evidencia insegura"

cleanup() {
  if $lock_acquired && owned_directory "$lock" && owned_regular "$lock/owner.pid"; then
    local owner=""; IFS= read -r owner < "$lock/owner.pid" || true
    if [[ "$owner" == "$$" ]]; then rm -f "$lock/owner.pid"; rmdir "$lock" 2>/dev/null || true; fi
  fi
}
trap cleanup EXIT INT TERM
# Eight concurrent writers can legitimately queue behind full ledger validation.
# Keep the bound finite, but leave enough time for the documented concurrency case.
deadline=$((SECONDS + 15))
while ! mkdir "$lock" 2>/dev/null; do
  safe_existing_directories || die "$BIA_PATH" "Lock inseguro"
  ((SECONDS < deadline)) || die "$BIA_TIMEOUT" "Timeout esperando lock"
  sleep 0.02
done
printf '%s\n' "$$" > "$lock/owner.pid" || die "$BIA_PATH" "No se pudo identificar el lock"
lock_acquired=true

validate_ledger || { code=$?; die "$code" "Ledger inválido"; }
timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)" || die "$BIA_LEDGER" "Reloj UTC no disponible"
validate_timestamp "$timestamp" || die "$BIA_LEDGER" "Timestamp UTC inválido"
event="$(jq -cn --arg timestamp "$timestamp" --arg task "$task_id" --arg phase "$phase" --arg test_id "$test_id" --argjson exit_code "$exit_code" --arg test_file "$test_file" --arg hash "$test_sha256" '{timestamp_utc:$timestamp,task_id:$task,phase:$phase,test_id:$test_id,exit_code:$exit_code,test_file:$test_file,test_sha256:$hash}')" || die "$BIA_LEDGER" "No se pudo construir el evento"
validate_event "$event" || die "$BIA_LEDGER" "Evento inválido"
[[ ! -e "$ledger" && ! -L "$ledger" ]] || owned_regular "$ledger" || die "$BIA_PATH" "Ledger inseguro"
printf '%s\n' "$event" >> "$ledger" || die "$BIA_LEDGER" "Append fallido"
sync -f "$ledger" || die "$BIA_LEDGER" "Sync fallido"
