#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/tailscale.sh"
if tailscale_installed; then
    command -v tailscale >/dev/null
    command -v tailscaled >/dev/null
fi
echo "OK alpine tailscale"
