#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/debian/modules/core.sh"
# shellcheck source=/dev/null
source "$ROOT_DIR/debian/modules/limits.sh"

if limits_configure_nofile invalid >/dev/null 2>&1; then
    printf 'ERROR limits_configure_nofile accepted an invalid value\n' >&2
    exit 1
fi

if limits_configure_nofile 100 >/dev/null 2>&1; then
    printf 'ERROR limits_configure_nofile accepted an unexpectedly low value\n' >&2
    exit 1
fi

printf 'OK limits validation smoke test passed\n'
