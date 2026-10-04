#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/network.sh"
source "$ROOT_DIR/alpine/modules/dhcp.sh"
source "$ROOT_DIR/alpine/modules/pppoe.sh"
source "$ROOT_DIR/alpine/modules/router-config.sh"
network_interface_exists() { case "$1" in wan0|lan0|lan1) return 0;; *) return 1;; esac; }
d="$(mktemp -d)"; trap 'rm -rf "$d"' EXIT
f="$d/router.conf"
cat >"$f" <<EOF
UPLINK=wan0
UPLINK_MODE=dhcp
LAN=lan0
LAN_ADDRESS=192.168.50.1/24
DHCP_RANGE=192.168.50.100-192.168.50.200
EOF
router_config_parse "$f"; router_config_validate
sed 's/192.168.50.100-192.168.50.200/192.168.51.10-192.168.51.20/' "$f" >"$f.tmp"
mv "$f.tmp" "$f"
router_config_parse "$f"; ! router_config_validate >/dev/null 2>&1
cat >"$f" <<EOF
UPLINK=wan0
UPLINK_MODE=dhcp
LAN=lan0
LAN_ADDRESS=192.168.50.1/24
DHCP_RANGE=192.168.50.100-192.168.50.200
SECOND_LAN=lan1
SECOND_LAN_ADDRESS=192.168.51.1/24
SECOND_DHCP_RANGE=192.168.51.50-192.168.51.100
EOF
router_config_parse "$f"; router_config_validate
sed 's/SECOND_LAN=lan1/SECOND_LAN=lan0/' "$f" >"$f.tmp"
mv "$f.tmp" "$f"
router_config_parse "$f"; ! router_config_validate >/dev/null 2>&1
sed 's/SECOND_LAN=lan0/SECOND_LAN=lan1/; s/192.168.51.1\/24/192.168.50.2\/24/' "$f" >"$f.tmp"
mv "$f.tmp" "$f"
router_config_parse "$f"; ! router_config_validate >/dev/null 2>&1
sed '/SECOND_DHCP_RANGE/d' "$f" >"$f.tmp"
mv "$f.tmp" "$f"
router_config_parse "$f"; ! router_config_validate >/dev/null 2>&1
secret="$d/secret"; printf 'secret\n' >"$secret"; chmod 600 "$secret"
cat >"$f" <<EOF
UPLINK=wan0
UPLINK_MODE=pppoe
LAN=lan0
LAN_ADDRESS=192.168.50.1/24
DHCP_RANGE=192.168.50.100-192.168.50.200
PPPOE_USER=user@example
PPPOE_SECRET_FILE=$secret
EOF
router_config_parse "$f"; router_config_validate
echo "OK alpine router-config"
