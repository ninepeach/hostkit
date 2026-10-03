#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/dhcp.sh"
dhcp_validate_ipv4_cidr 192.168.50.1/24
! dhcp_validate_ipv4_cidr 192.168.50.1/31
dhcp_range_usable_for_lan 192.168.50.1/24 192.168.50.100-192.168.50.200
! dhcp_range_usable_for_lan 192.168.50.1/24 192.168.51.10-192.168.51.20
! dhcp_range_usable_for_lan 192.168.50.1/24 192.168.50.1-192.168.50.20
! dhcp_range_usable_for_lan 192.168.50.1/24 192.168.50.200-192.168.50.255
echo "OK alpine dhcp"
