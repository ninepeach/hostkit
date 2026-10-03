#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/network.sh"
source "$ROOT_DIR/alpine/modules/pppoe.sh"
out="$(pppoe_render_peer eth0 'user@example')"
grep -q '^user "user@example"$' <<<"$out"
grep -q '^plugin pppoe.so eth0$' <<<"$out"
grep -q '^defaultroute$' <<<"$out"
grep -q '^persist$' <<<"$out"
! pppoe_render_peer 'bad name' user >/dev/null 2>&1
! pppoe_render_peer eth0 'bad"user' >/dev/null 2>&1
! pppoe_render_peer eth0 'bad user' >/dev/null 2>&1
echo "OK alpine pppoe"
