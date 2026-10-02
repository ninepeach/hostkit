#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

before_flags="$-"
before_err_trap="$(trap -p ERR || true)"
before_exit_trap="$(trap -p EXIT || true)"

# shellcheck source=/dev/null
source "$ROOT_DIR/debian/modules/core.sh"

test "$-" = "$before_flags"
test "$(trap -p ERR || true)" = "$before_err_trap"
test "$(trap -p EXIT || true)" = "$before_exit_trap"

for fn in log_info log_warn log_error log_ok die require_root require_command require_debian_13; do
    declare -F "$fn" >/dev/null
done

require_command sh printf grep

if require_command hostkit-command-that-must-not-exist >/dev/null 2>&1; then
    printf 'ERROR require_command accepted a missing command\n' >&2
    exit 1
fi

printf 'OK module contract smoke test passed\n'
