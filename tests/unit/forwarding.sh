source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/forwarding.sh"

test_not_ok "invalid IPv4 forwarding rejected" forwarding_set_ipv4 2
test_not_ok "invalid IPv6 forwarding rejected" forwarding_set_ipv6 yes
