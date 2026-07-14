#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

issue_number() {
  local body="${PR_BODY-}"
  local match

  shopt -s nocasematch
  if [[ "$body" =~ (^|[^[:alnum:]_])(closes|fixes|resolves)[[:space:]]+#([0-9]+)([^[:alnum:]_-]|$) ]]; then
    match="${BASH_REMATCH[3]}"
    printf '%s\n' "$match"
    return
  fi

  fail 'PR body must link an issue with Closes, Fixes, or Resolves #N'
}

if (( $# > 1 )); then
  fail 'usage: validate-pr.sh [--issue-number]'
fi

if (( $# == 1 )); then
  [[ "$1" == '--issue-number' ]] || fail 'usage: validate-pr.sh [--issue-number]'
  issue_number
  exit 0
fi

linked_issue="$(issue_number)" || exit 1
readonly linked_issue

if ! jq -e 'type == "object"' <<<"${ISSUE_JSON-}" >/dev/null 2>&1; then
  fail "linked target #${linked_issue} returned invalid issue data"
fi

if jq -e 'has("pull_request")' <<<"${ISSUE_JSON-}" >/dev/null; then
  fail "linked target #${linked_issue} is a pull request, not an issue"
fi

if ! jq -e \
  '[.labels[]?.name] | index("status:approved") != null' \
  <<<"${ISSUE_JSON-}" >/dev/null; then
  fail "linked issue #${linked_issue} must have status:approved"
fi

type_count="$({
  awk 'index($0, "type:") == 1 { count++ } END { print count + 0 }' \
    <<<"${PR_LABELS-}"
})"
readonly type_count

if [[ "$type_count" != '1' ]]; then
  fail "PR must have exactly one type:* label; found ${type_count}"
fi

printf 'PR policy valid: approved issue #%s and one type:* label\n' "$linked_issue"
