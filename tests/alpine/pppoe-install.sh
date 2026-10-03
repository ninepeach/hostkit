#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/network.sh"
source "$ROOT_DIR/alpine/modules/pppoe.sh"
d="$(mktemp -d)"; trap 'rm -rf "$d"' EXIT
src="$d/source"; export HOSTKIT_PPPOE_PEER_PATH="$d/peer"
pppoe_render_peer eth0 user >"$src"
pppoe_install_peer "$src"
test "$(stat -c %a "$HOSTKIT_PPPOE_PEER_PATH")" = 600
printf 'foreign\n' >"$HOSTKIT_PPPOE_PEER_PATH"
! pppoe_install_peer "$src" >/dev/null 2>&1
echo "OK alpine pppoe install"
