#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/integration/lib/netns.sh"

[ "${EUID:-$(id -u)}" -eq 0 ] || { printf 'SKIP network namespace integration requires root\n'; exit 0; }
netns_supported || { printf 'SKIP network namespaces unavailable\n'; exit 0; }

ns="hk-net-$$"
host_if="hkh$$"
ns_if="hkn$$"
cleanup() {
    ip link del "$host_if" >/dev/null 2>&1 || true
    netns_delete "$ns"
}
trap cleanup EXIT

printf 'integration: isolated veth namespace... '
netns_create_pair "$ns" "$host_if" "$ns_if"
ip addr add 192.0.2.1/30 dev "$host_if"
ip -n "$ns" addr add 192.0.2.2/30 dev "$ns_if"
ip netns exec "$ns" ping -c 1 -W 2 192.0.2.1 >/dev/null
ping -c 1 -W 2 -I "$host_if" 192.0.2.2 >/dev/null
printf 'OK\n'

printf 'OK isolated network runtime substrate passed\n'
