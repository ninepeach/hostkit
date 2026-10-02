#!/usr/bin/env bash
set -Eeuo pipefail

test_file="$1"
source "$ROOT_DIR/tests/lib/test.sh"
source "$ROOT_DIR/tests/lib/mock.sh"

cleanup() {
    if [ -n "${HOSTKIT_MOCK_DIR:-}" ]; then
        mock_end
    fi
}
trap cleanup EXIT

source "$test_file"
test_summary
