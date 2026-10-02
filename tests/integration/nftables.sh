#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/debian/modules/nftables.sh"

[ "${EUID:-$(id -u)}" -eq 0 ] || { printf 'SKIP nftables integration requires root\n'; exit 0; }
command -v nft >/dev/null || { printf 'SKIP nft unavailable\n'; exit 0; }

tmp="$(mktemp)"
backup="$(mktemp)"
table="hostkit_integration_$$"
cleanup() { nft delete table inet "$table" >/dev/null 2>&1 || true; rm -f "$tmp" "$backup"; }
trap cleanup EXIT

cat >"$tmp" <<EOF
table inet $table {
    chain input {
        type filter hook input priority 0; policy accept;
    }
}
EOF

printf 'integration: nft syntax validation... '
nft_validate "$tmp"
printf 'OK\n'

printf 'integration: nft apply and live ruleset... '
nft_apply "$tmp"
nft list table inet "$table" >/dev/null
printf 'OK\n'

printf 'integration: nft backup captures live ruleset... '
nft_backup "$backup"
grep -Fq "table inet $table" "$backup"
printf 'OK\n'
