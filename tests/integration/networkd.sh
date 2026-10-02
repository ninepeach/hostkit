#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/networkd.sh"

command -v systemd-analyze >/dev/null || { printf 'SKIP systemd-analyze unavailable\n'; exit 0; }

tmpdir="$(mktemp -d)"
source_file="$tmpdir/source.network"
export HOSTKIT_NETWORKD_DIR="$tmpdir/installed"
trap 'rm -rf "$tmpdir"' EXIT

cat >"$source_file" <<'EOF'
[Match]
Name=hostkit-test0

[Network]
Address=192.0.2.1/30
EOF

printf 'integration: networkd managed file install... '
networkd_validate_network_file "$source_file"
networkd_install_network_file 90-hostkit-test.network "$source_file"
networkd_hostkit_owned "$HOSTKIT_NETWORKD_DIR/90-hostkit-test.network"
grep -Fqx 'Address=192.0.2.1/30' "$HOSTKIT_NETWORKD_DIR/90-hostkit-test.network"
printf 'OK\n'

printf 'integration: foreign networkd file protection... '
printf '%s\n' '# administrator owned' >"$HOSTKIT_NETWORKD_DIR/90-hostkit-test.network"
if networkd_install_network_file 90-hostkit-test.network "$source_file"; then
    printf 'FAIL\n'
    exit 1
fi
grep -Fqx '# administrator owned' "$HOSTKIT_NETWORKD_DIR/90-hostkit-test.network"
printf 'OK\n'
