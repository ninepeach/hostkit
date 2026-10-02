#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

check_artifact() {
    local product="$1"
    shift
    "$ROOT_DIR/tools/build.sh" "$product"
    local artifact="$ROOT_DIR/dist/debian13-$product.sh"

    test -x "$artifact"
    bash -n "$artifact"
    grep -q "^# Product: ${product^^}$" "$artifact"
    grep -q '^# Platform: Debian 13$' "$artifact"
    grep -q '^set -Eeuo pipefail$' "$artifact"
    grep -q '^hostkit_main "$@"$' "$artifact"

    local module count
    for module in "$@"; do
        count="$(grep -c "^# ---- module: $module ----$" "$artifact")"
        if [ "$count" -ne 1 ]; then
            printf 'ERROR module %s occurs %s times in %s\n' "$module" "$count" "$artifact" >&2
            exit 1
        fi
    done
}

check_artifact init core apt packages limits locale hostname timezone network-tools chrony unattended-upgrades system-health
check_artifact router core network forwarding nftables nat router-firewall

printf 'OK build smoke tests passed\n'
