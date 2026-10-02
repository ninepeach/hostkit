source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/unattended-upgrades.sh"

tmpdir="$(mktemp -d)"
export HOSTKIT_UNATTENDED_PATH="$tmpdir/52hostkit-unattended-upgrades"

test_ok "managed unattended-upgrades file created" unattended_upgrades_enable
test_ok "managed unattended-upgrades file is idempotent" unattended_upgrades_enable
grep -Fqx 'APT::Periodic::Unattended-Upgrade "1";' "$HOSTKIT_UNATTENDED_PATH" || test_fail "upgrade policy written"
grep -Fqx 'Unattended-Upgrade::Automatic-Reboot "false";' "$HOSTKIT_UNATTENDED_PATH" || test_fail "reboot policy written"

printf '%s\n' '# administrator owned' >"$HOSTKIT_UNATTENDED_PATH"
test_not_ok "foreign unattended-upgrades file is preserved" unattended_upgrades_enable
test_eq "foreign unattended content unchanged" '# administrator owned' "$(cat "$HOSTKIT_UNATTENDED_PATH")"

rm -rf "$tmpdir"
