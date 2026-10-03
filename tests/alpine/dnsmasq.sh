#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/dnsmasq.sh"
out="$(dnsmasq_render lan0 192.168.50.1/24 192.168.50.100-192.168.50.200)"
grep -q '^interface=lan0$' <<<"$out"
grep -q '^dhcp-range=192.168.50.100,192.168.50.200,12h$' <<<"$out"
grep -q '^dhcp-option=option:router,192.168.50.1$' <<<"$out"
echo "OK alpine dnsmasq"
