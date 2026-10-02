#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/transaction.sh"

[ "${EUID:-$(id -u)}" -eq 0 ] || { printf 'SKIP transaction integration test requires root\n'; exit 0; }
command -v systemd-run >/dev/null || { printf 'SKIP systemd-run unavailable\n'; exit 0; }
systemctl is-system-running >/dev/null 2>&1 || {
    state="$(systemctl is-system-running 2>/dev/null || true)"
    [ "$state" = degraded ] || { printf 'SKIP systemd is not running\n'; exit 0; }
}

tmpdir="$(mktemp -d)"
marker="$tmpdir/rolled-back"
rollback="$tmpdir/rollback.sh"

cleanup() {
    transaction_disarm >/dev/null 2>&1 || true
    rm -rf "$tmpdir"
}
trap cleanup EXIT

cat >"$rollback" <<EOF
#!/usr/bin/env bash
printf '%s\\n' rollback >"$marker"
EOF
chmod 700 "$rollback"

printf 'integration: automatic rollback fires... '
transaction_begin integration-auto
transaction_arm "$rollback" 30
for _ in $(seq 1 40); do
    [ -f "$marker" ] && break
    sleep 1
done
[ -f "$marker" ] || { printf 'FAIL\n'; exit 1; }
HOSTKIT_TRANSACTION_ARMED=0
HOSTKIT_TRANSACTION_UNIT=
HOSTKIT_TRANSACTION_ROLLBACK=
HOSTKIT_TRANSACTION_GUARD=
HOSTKIT_TRANSACTION_WRAPPER=
printf 'OK\n'

rm -f "$marker"
printf 'integration: commit cancels rollback... '
transaction_begin integration-commit
transaction_arm "$rollback" 30
transaction_commit
sleep 32
[ ! -e "$marker" ] || { printf 'FAIL\n'; exit 1; }
printf 'OK\n'

printf 'OK transaction integration tests passed\n'
