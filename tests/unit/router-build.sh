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
forwarding_write_persistent() { return 0; }
forwarding_set_ipv4() { return 0; }
forwarding_ipv4_enabled() { return 0; }

network_detect_uplink() { printf '%s\n' eth0; }
test_ok "ROUTER accepts one unambiguous uplink" hostkit_main

network_detect_uplink() { return 1; }
test_not_ok "ROUTER rejects missing uplink" hostkit_main

network_detect_uplink() { return 2; }
test_not_ok "ROUTER rejects ambiguous uplinks" hostkit_main

network_detect_uplink() { printf '%s\n' eth0; }
test_not_ok "ROUTER rejects unreleased configured mode" hostkit_main /tmp/router.conf
