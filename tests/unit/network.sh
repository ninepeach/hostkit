source "$ROOT_DIR/debian/modules/network.sh"

test_ok "eth0 interface name" network_validate_interface_name eth0
test_ok "predictable interface name" network_validate_interface_name enp1s0
test_not_ok "empty interface rejected" network_validate_interface_name ""
test_not_ok "interface with space rejected" network_validate_interface_name "bad interface"
