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

rm -f "$tmp"
