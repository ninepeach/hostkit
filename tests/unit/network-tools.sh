source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network-tools.sh"

network_default_route_available() { return 0; }
network_dns_available() { return 0; }
test_ok "connectivity accepts route and DNS" network_require_connectivity

network_dns_available() { return 1; }
test_not_ok "connectivity rejects missing DNS" network_require_connectivity
