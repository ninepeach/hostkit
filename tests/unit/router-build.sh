source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network.sh"
source "$ROOT_DIR/debian/modules/forwarding.sh"
source "$ROOT_DIR/debian/modules/nftables.sh"
source "$ROOT_DIR/debian/modules/nat.sh"
source "$ROOT_DIR/debian/modules/router-firewall.sh"
source "$ROOT_DIR/debian/build/router.sh"

require_root() { return 0; }
require_debian_13() { return 0; }
require_command() { return 0; }
forwarding_write_persistent() { ROUTER_TEST_PERSIST="$1:$2"; return 0; }
forwarding_set_ipv4() { return 0; }
forwarding_ipv4_enabled() { return 0; }
forwarding_ipv6_enabled() { return 1; }

network_detect_uplink() { printf '%s\n' eth0; }
test_ok "ROUTER accepts one unambiguous uplink" hostkit_main
test_eq "ROUTER preserves disabled IPv6 forwarding" "1:0" "$ROUTER_TEST_PERSIST"

forwarding_ipv6_enabled() { return 0; }
test_ok "ROUTER accepts existing IPv6 forwarding" hostkit_main
test_eq "ROUTER preserves enabled IPv6 forwarding" "1:1" "$ROUTER_TEST_PERSIST"
forwarding_ipv6_enabled() { return 1; }

network_detect_uplink() { return 1; }
test_not_ok "ROUTER rejects missing uplink" hostkit_main

network_detect_uplink() { return 2; }
test_not_ok "ROUTER rejects ambiguous uplinks" hostkit_main

network_detect_uplink() { printf '%s\n' eth0; }
test_not_ok "ROUTER rejects unreleased configured mode" hostkit_main /tmp/router.conf
