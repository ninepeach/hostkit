#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/forwarding.sh"
d="$(mktemp -d)"; trap 'rm -rf "$d"' EXIT
export HOSTKIT_SYSCTL_FILE="$d/forwarding.conf"
forwarding_write_persistent 1 0
grep -qx '# Managed by HostKit. Do not edit manually.' "$HOSTKIT_SYSCTL_FILE"
grep -qx 'net.ipv4.ip_forward = 1' "$HOSTKIT_SYSCTL_FILE"
printf 'foreign\n' >"$HOSTKIT_SYSCTL_FILE"
! forwarding_write_persistent 1 0 >/dev/null 2>&1
echo "OK alpine forwarding"
