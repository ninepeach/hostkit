source "$ROOT_DIR/debian/modules/dhcp.sh"

test_ok "valid IPv4" dhcp_validate_ipv4 192.168.10.1
test_not_ok "invalid octet" dhcp_validate_ipv4 192.168.10.999
test_not_ok "short IPv4 rejected" dhcp_validate_ipv4 192.168.1
test_not_ok "leading-zero octet rejected" dhcp_validate_ipv4 192.168.010.1
test_ok "valid DHCP range" dhcp_validate_range 192.168.10.100-192.168.10.200
test_not_ok "single address is not range" dhcp_validate_range 192.168.10.100
test_not_ok "reversed DHCP range rejected" dhcp_validate_range 192.168.10.200-192.168.10.100
test_ok "valid IPv4 CIDR" dhcp_validate_ipv4_cidr 192.168.10.1/24
test_not_ok "CIDR prefix too large" dhcp_validate_ipv4_cidr 192.168.10.1/33
test_not_ok "CIDR prefix leading zero rejected" dhcp_validate_ipv4_cidr 192.168.10.1/024
