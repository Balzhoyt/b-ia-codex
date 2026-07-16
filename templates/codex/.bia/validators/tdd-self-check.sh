#!/usr/bin/env bash
set -euo pipefail

root="$(pwd -P)"
exec "$root/.bia/validators/tdd-event.sh" --verify

