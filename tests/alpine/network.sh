#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/network.sh"
network_validate_interface_name eth0
network_validate_interface_name tailscale0
if network_validate_interface_name 'bad name'; then
    echo "ERROR invalid interface accepted" >&2; exit 1
fi
echo "OK alpine network"
