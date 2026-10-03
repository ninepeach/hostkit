#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/network-config.sh"
out="$(network_config_render wan0 lan0 192.168.50.1/24)"
grep -q '^auto wan0$' <<<"$out"
grep -q '^iface wan0 inet dhcp$' <<<"$out"
grep -q '^auto lan0$' <<<"$out"
grep -q 'address 192.168.50.1/24' <<<"$out"
echo "OK alpine network-config"
