#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="${1:-}"

source "$ROOT_DIR/tests/lib/test.sh"
source "$ROOT_DIR/tests/lib/mock.sh"

run_one() {
    local module="$1"
    local test_file="$ROOT_DIR/tests/unit/$module.sh"

    if [ ! -r "$test_file" ]; then
        printf 'ERROR no unit test for module: %s\n' "$module" >&2
        return 2
    fi

    printf 'Testing module: %s\n\n' "$module"
    TEST_PASSED=0
    TEST_FAILED=0
    source "$test_file"
    test_summary
}

if [ -z "$MODULE" ]; then
    printf 'Usage: %s <module|all>\n' "$0" >&2
    exit 2
fi

if [ "$MODULE" = all ]; then
    total_failed=0
    for test_file in "$ROOT_DIR"/tests/unit/*.sh; do
        module="$(basename "$test_file" .sh)"
        run_one "$module" || total_failed=1
        printf '\n'
    done
    exit "$total_failed"
fi

run_one "$MODULE"
