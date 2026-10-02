source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/user.sh"
source "$ROOT_DIR/debian/modules/sudo.sh"

tmp="$(mktemp)"
printf 'admin ALL=(ALL:ALL) ALL\n' >"$tmp"

mock_begin
mock_command visudo 'exit 0'
test_ok "valid sudoers accepted" sudo_validate_file "$tmp"
mock_end

mock_begin
mock_command visudo 'exit 1'
test_not_ok "invalid sudoers rejected" sudo_validate_file "$tmp"
mock_end

test_not_ok "invalid user rejected before install" sudo_install_admin_rule 'Bad User' "$tmp"
test_not_ok "missing source rejected" sudo_install_admin_rule admin "$tmp.missing"

tmpdir="$(mktemp -d)"
export HOSTKIT_SUDOERS_DIR="$tmpdir"
mock_begin
mock_command visudo 'exit 0'
test_ok "managed sudo rule installed" sudo_install_admin_rule admin "$tmp"
test_ok "managed sudo rule idempotent" sudo_install_admin_rule admin "$tmp"
printf '%s\n' '# administrator owned' >"$tmpdir/90-hostkit-admin"
test_not_ok "foreign sudo rule preserved" sudo_install_admin_rule admin "$tmp"
test_eq "foreign sudo content unchanged" '# administrator owned' "$(cat "$tmpdir/90-hostkit-admin")"
mock_end
unset HOSTKIT_SUDOERS_DIR
rm -rf "$tmpdir"

rm -f "$tmp"
