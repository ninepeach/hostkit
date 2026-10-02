#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/tests/integration/lib/netns.sh"
source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network.sh"
source "$ROOT_DIR/debian/modules/nat.sh"
source "$ROOT_DIR/debian/modules/router-firewall.sh"

[ "${EUID:-$(id -u)}" -eq 0 ] || { printf 'SKIP router datapath integration requires root\n'; exit 0; }
command -v nft >/dev/null || { printf 'SKIP nft unavailable\n'; exit 0; }
netns_supported || { printf 'SKIP network namespaces unavailable\n'; exit 0; }

lan_ns="hk-lan-$$"
wan_ns="hk-wan-$$"
lan_host="hklh$$"
lan_peer="hklp$$"
wan_host="hkwh$$"
wan_peer="hkwp$$"
table="hostkit_router_test_$$"
old_forward="$(sysctl -n net.ipv4.ip_forward)"

cleanup() {
    nft delete table inet "$table" >/dev/null 2>&1 || true
    nft delete table ip "${table}_nat" >/dev/null 2>&1 || true
    sysctl -w "net.ipv4.ip_forward=$old_forward" >/dev/null 2>&1 || true
    ip link del "$lan_host" >/dev/null 2>&1 || true
    ip link del "$wan_host" >/dev/null 2>&1 || true
    netns_delete "$lan_ns"
    netns_delete "$wan_ns"
}
trap cleanup EXIT

netns_create_pair "$lan_ns" "$lan_host" "$lan_peer"
netns_create_pair "$wan_ns" "$wan_host" "$wan_peer"

ip addr add 192.168.250.1/24 dev "$lan_host"
ip -n "$lan_ns" addr add 192.168.250.2/24 dev "$lan_peer"
ip -n "$lan_ns" route add default via 192.168.250.1

ip addr add 198.51.100.1/24 dev "$wan_host"
ip -n "$wan_ns" addr add 198.51.100.2/24 dev "$wan_peer"

sysctl -w net.ipv4.ip_forward=1 >/dev/null

rules="$(mktemp)"
router_firewall_render "$lan_host" "$wan_host" "$table" "${table}_nat" >"$rules"
trap 'rm -f "$rules"; cleanup' EXIT

printf 'integration: isolated router forwarding and NAT44... '
nft --check --file "$rules"
nft --file "$rules"
ip netns exec "$lan_ns" ping -c 1 -W 2 198.51.100.2 >/dev/null
printf 'OK\n'

printf 'integration: NAT hides LAN source from WAN peer... '
ip netns exec "$wan_ns" ip neigh flush dev "$wan_peer" >/dev/null 2>&1 || true
ip netns exec "$lan_ns" ping -c 1 -W 2 198.51.100.2 >/dev/null
if ip netns exec "$wan_ns" ip neigh show | grep -Fq '192.168.250.2'; then
    printf 'FAIL\n'
    exit 1
fi
printf 'OK\n'

printf 'OK isolated ROUTER datapath integration passed\n'
