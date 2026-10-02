source "$ROOT_DIR/debian/modules/networkd.sh"

test_ok "networkd validator exported" declare -F networkd_validate_network_file
test_ok "networkd reload exported" declare -F networkd_reload
test_ok "networkd active check exported" declare -F networkd_is_active
