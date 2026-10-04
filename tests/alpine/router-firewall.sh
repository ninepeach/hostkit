#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/network.sh"
source "$ROOT_DIR/alpine/modules/router-firewall.sh"
network_interface_exists() { return 0; }
rules="$(router_firewall_render lan0 wan0)"
grep -q 'policy drop' <<<"$rules"
grep -q 'ct state established,related accept' <<<"$rules"
grep -q 'iifname "lan0" oifname "wan0" accept' <<<"$rules"
grep -q 'oifname "wan0" masquerade' <<<"$rules"
if grep -q 'tcp option maxseg size set rt mtu' <<<"$rules"; then
    echo "ERROR DHCP WAN renderer added MSS clamp" >&2; exit 1
fi
if router_firewall_render wan0 wan0 >/dev/null 2>&1; then
    echo "ERROR same LAN/WAN accepted" >&2; exit 1
fi

rules="$(router_firewall_render_pppoe_unchecked lan0 ppp0)"
grep -q 'oifname "ppp0" tcp flags syn tcp option maxseg size set rt mtu' <<<"$rules"
grep -q 'iifname "lan0" oifname "ppp0" accept' <<<"$rules"
grep -q 'oifname "ppp0" masquerade' <<<"$rules"

echo "OK alpine router-firewall"
