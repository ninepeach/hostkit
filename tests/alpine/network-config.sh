#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/network-config.sh"
out="$(network_config_render_dhcp wan0 lan0 192.168.50.1/24)"
grep -q '^auto wan0$' <<<"$out"
grep -q '^iface wan0 inet dhcp$' <<<"$out"
grep -q '^iface lan0 inet static$' <<<"$out"
grep -q 'address 192.168.50.1/24' <<<"$out"
out="$(network_config_render_pppoe_lan lan0 192.168.50.1/24)"
! grep -q 'wan0' <<<"$out"
grep -q '^iface lan0 inet static$' <<<"$out"
echo "OK alpine network-config"
