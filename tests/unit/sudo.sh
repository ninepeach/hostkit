source "$ROOT_DIR/debian/modules/sudo.sh"

test_ok "sudo validator exported" declare -F sudo_validate_file
test_ok "sudo installer exported" declare -F sudo_install_admin_rule
