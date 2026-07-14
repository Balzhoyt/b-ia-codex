#!/usr/bin/env bash
set -euo pipefail

readonly VALIDATOR="scripts/validate-pr.sh"
readonly POLICY_WORKFLOW=".github/workflows/pr-policy.yml"
readonly REPOSITORY_WORKFLOW=".github/workflows/pr-validation.yml"
readonly APPROVED_ISSUE='{"labels":[{"name":"status:approved"}]}'
readonly CHECKOUT_SHA='actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683'

run_validator() {
  PR_BODY="$1" \
    PR_LABELS="$2" \
    ISSUE_JSON="$3" \
    bash "$VALIDATOR"
}

expect_failure() {
  local description="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    printf 'FAIL: %s\n' "$description" >&2
    return 1
  fi
}

assert_line() {
  local file="$1"
  local expected="$2"

  grep -Fqx "$expected" "$file" || {
    printf 'FAIL: %s lacks structural line: %s\n' "$file" "$expected" >&2
    return 1
  }
}

run_validator 'Closes #4' 'type:chore' "$APPROVED_ISSUE" >/dev/null

expect_failure 'missing linked issue must fail' \
  run_validator 'No issue reference' 'type:chore' "$APPROVED_ISSUE"
expect_failure 'keyword substrings must not count as links' \
  run_validator 'This discloses #4' 'type:chore' "$APPROVED_ISSUE"
expect_failure 'issue number suffix letters must fail' \
  run_validator 'Closes #4abc' 'type:chore' "$APPROVED_ISSUE"
expect_failure 'issue number suffix underscores must fail' \
  run_validator 'Closes #4_foo' 'type:chore' "$APPROVED_ISSUE"
expect_failure 'issue number suffix hyphens must fail' \
  run_validator 'Closes #4-foo' 'type:chore' "$APPROVED_ISSUE"
expect_failure 'missing approved issue label must fail' \
  run_validator 'Fixes #4' 'type:chore' '{"labels":[{"name":"status:triage"}]}'
expect_failure 'malformed issue data must fail' \
  run_validator 'Fixes #4' 'type:chore' 'not-json'
expect_failure 'linked pull requests must not count as issues' \
  run_validator 'Fixes #4' 'type:chore' \
    '{"labels":[{"name":"status:approved"}],"pull_request":{}}'
expect_failure 'missing type label must fail' \
  run_validator 'Resolves #4' 'status:approved' "$APPROVED_ISSUE"
expect_failure 'multiple type labels must fail' \
  run_validator 'Closes #4' $'type:chore\ntype:feature' "$APPROVED_ISSUE"

issue_number="$(PR_BODY='FIXES #42' bash "$VALIDATOR" --issue-number)"
[[ "$issue_number" == '42' ]] || {
  printf 'FAIL: expected issue number 42, got %s\n' "$issue_number" >&2
  exit 1
}

assert_line "$POLICY_WORKFLOW" '  pull_request_target:'
assert_line "$POLICY_WORKFLOW" 'permissions: {}'
assert_line "$POLICY_WORKFLOW" '      contents: read'
assert_line "$POLICY_WORKFLOW" '      issues: read'
grep -Fq 'github.event.pull_request.base.sha' "$POLICY_WORKFLOW"
assert_line "$POLICY_WORKFLOW" '          persist-credentials: false'
assert_line "$POLICY_WORKFLOW" "        uses: $CHECKOUT_SHA"
assert_line "$REPOSITORY_WORKFLOW" '  pull_request:'
assert_line "$REPOSITORY_WORKFLOW" 'permissions: {}'
assert_line "$REPOSITORY_WORKFLOW" '      contents: read'
assert_line "$REPOSITORY_WORKFLOW" '          persist-credentials: false'
assert_line "$REPOSITORY_WORKFLOW" "        uses: $CHECKOUT_SHA"

[[ "$(grep -Fc '      issues: read' "$POLICY_WORKFLOW")" == '1' ]]

if grep -Fq 'pull_request_target' "$REPOSITORY_WORKFLOW"; then
  printf 'FAIL: repository checks must not use pull_request_target\n' >&2
  exit 1
fi
if grep -Fq 'pull_request.head' "$POLICY_WORKFLOW"; then
  printf 'FAIL: trusted policy must never checkout PR-controlled code\n' >&2
  exit 1
fi
if grep -Eq 'uses: actions/checkout@v[0-9]' "$POLICY_WORKFLOW" "$REPOSITORY_WORKFLOW"; then
  printf 'FAIL: third-party actions must use immutable SHAs\n' >&2
  exit 1
fi
if grep -Eq '^      [a-z-]+: write$' "$REPOSITORY_WORKFLOW"; then
  printf 'FAIL: repository checks must not receive write permissions\n' >&2
  exit 1
fi

grep -Fq "bash -n \"\$file\"" "$REPOSITORY_WORKFLOW"
grep -Fq "shellcheck \"\$file\"" "$REPOSITORY_WORKFLOW"
grep -Fq 'bash tests/contracts/run.sh' "$REPOSITORY_WORKFLOW"
grep -Fq 'bootstrap skip is intentional' "$REPOSITORY_WORKFLOW"
if grep -Fq 'chmod ' "$REPOSITORY_WORKFLOW"; then
  printf 'FAIL: contract execution must not mutate file modes\n' >&2
  exit 1
fi

# Issue approval changes must refresh a durable policy status on linked PR heads.
assert_line "$POLICY_WORKFLOW" '  issues:'
assert_line "$POLICY_WORKFLOW" '    types: [labeled, unlabeled]'
assert_line "$POLICY_WORKFLOW" '      pull-requests: read'
assert_line "$POLICY_WORKFLOW" '      statuses: write'
grep -Fq '/statuses/' "$POLICY_WORKFLOW"
grep -Fq "context='PR policy'" "$POLICY_WORKFLOW"
grep -Fq 'pulls?state=open&base=main&per_page=100' "$POLICY_WORKFLOW"

printf 'PASS: PR validation fails closed and workflows preserve trust boundaries\n'
