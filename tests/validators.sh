#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for module in core hostname user ssh network pppoe router-config transaction dhcp; do
    source "$ROOT_DIR/debian/modules/$module.sh"
done

hostname_validate host01
hostname_validate host01.example
! hostname_validate ''
! hostname_validate '.bad'
! hostname_validate 'bad..name'

user_validate_name admin
user_validate_name ops-user
! user_validate_name 'Root'
! user_validate_name 'bad user'

ssh_validate_port 22
ssh_validate_port 65535
! ssh_validate_port 0
! ssh_validate_port 65536
! ssh_validate_port abc

network_validate_interface_name eth0
network_validate_interface_name enp1s0
! network_validate_interface_name ''
! network_validate_interface_name 'bad interface'

pppoe_validate_user 'user@example.com'
! pppoe_validate_user ''

transaction_validate_timeout 180
! transaction_validate_timeout 10
! transaction_validate_timeout 99999

dhcp_validate_ipv4 192.168.10.1
! dhcp_validate_ipv4 192.168.10.999
! dhcp_validate_ipv4 192.168.1

dhcp_validate_range 192.168.10.100-192.168.10.200
! dhcp_validate_range 192.168.10.100

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<'EOF'
UPLINK=eth0
UPLINK_MODE=dhcp
LAN=eth1
LAN_ADDRESS=192.168.10.1/24
DHCP_RANGE=192.168.10.100-192.168.10.200
EOF
router_config_parse "$tmp"
router_config_validate
[ "$UPLINK" = eth0 ]
[ "$LAN" = eth1 ]

cat >"$tmp" <<'EOF'
UNKNOWN=value
EOF
! router_config_parse "$tmp" >/dev/null 2>&1

printf 'OK validator unit tests passed\n'
