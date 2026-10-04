#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

check_artifact() {
    local platform="$1" product="$2" artifact="$3" platform_label="$4"
    shift 4
    bash "$ROOT_DIR/tools/build.sh" "$platform" "$product"

    test -x "$artifact"
    bash -n "$artifact"
    grep -q "^# Product: ${product^^}$" "$artifact"
    grep -q "^# Platform: $platform_label$" "$artifact"
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

# Legacy one-argument Debian build remains supported.
bash "$ROOT_DIR/tools/build.sh" router
test -x "$ROOT_DIR/dist/debian13-router.sh"

check_artifact debian init "$ROOT_DIR/dist/debian13-init.sh" "Debian 13" \
    core apt packages limits locale hostname timezone network-tools chrony unattended-upgrades system-health
check_artifact debian router "$ROOT_DIR/dist/debian13-router.sh" "Debian 13" \
    core network forwarding nftables nat router-firewall
check_artifact alpine router "$ROOT_DIR/dist/alpine-router.sh" "Alpine Linux" \
    core network dhcp router-config network-config forwarding nftables router-firewall router-nftables dnsmasq pppoe

printf 'OK build smoke tests passed\n'
