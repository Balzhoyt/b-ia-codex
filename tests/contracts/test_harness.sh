#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
test -x "$root/tests/contracts/run.sh"
grep -q 'tdd: true' "$root/openspec/config.yaml"
grep -q 'test_command: "bash tests/contracts/run.sh"' "$root/openspec/config.yaml"
test -s "$root/templates/codex/AGENTS.md"
test ! -e "$root/.bia/constitution.md"

probe="$(mktemp -d)"; trap 'rm -rf "$probe"' EXIT
cat > "$probe/test_pass.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
BIA_CONTRACT_DIR="$probe" "$root/tests/contracts/run.sh" | grep -q 'PASS: 1 contract test files'
cat > "$probe/test_fail.sh" <<'EOF'
#!/usr/bin/env bash
exit 7
EOF
set +e; BIA_CONTRACT_DIR="$probe" "$root/tests/contracts/run.sh" >/dev/null 2>&1; code=$?; set -e
test "$code" -eq 7
