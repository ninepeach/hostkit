#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/forwarding.sh"

[ "${EUID:-$(id -u)}" -eq 0 ] || { printf 'SKIP forwarding integration requires root\n'; exit 0; }
command -v sysctl >/dev/null || { printf 'SKIP sysctl unavailable\n'; exit 0; }

old4="$(sysctl -n net.ipv4.ip_forward)"
old6="$(sysctl -n net.ipv6.conf.all.forwarding)"
tmpdir="$(mktemp -d)"
export HOSTKIT_SYSCTL_PATH="$tmpdir/90-hostkit-router.conf"
cleanup() {
    sysctl -w "net.ipv4.ip_forward=$old4" >/dev/null 2>&1 || true
    sysctl -w "net.ipv6.conf.all.forwarding=$old6" >/dev/null 2>&1 || true
    rm -rf "$tmpdir"
}
trap cleanup EXIT

printf 'integration: runtime forwarding setters... '
forwarding_set_ipv4 1
forwarding_ipv4_enabled
forwarding_set_ipv6 1
forwarding_ipv6_enabled
printf 'OK\n'

printf 'integration: persistent forwarding file... '
forwarding_write_persistent 1 1
grep -Fqx 'net.ipv4.ip_forward=1' "$HOSTKIT_SYSCTL_PATH"
grep -Fqx 'net.ipv6.conf.all.forwarding=1' "$HOSTKIT_SYSCTL_PATH"
printf 'OK\n'
