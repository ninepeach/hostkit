#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/dnsmasq.sh"

command -v dnsmasq >/dev/null || { printf 'SKIP dnsmasq unavailable\n'; exit 0; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<'EOF'
port=0
no-daemon
EOF

printf 'integration: dnsmasq validates generated-style config... '
dnsmasq_validate "$tmp"
printf 'OK\n'
