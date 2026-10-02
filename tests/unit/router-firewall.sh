source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network.sh"
source "$ROOT_DIR/debian/modules/router-firewall.sh"

network_interface_exists() { return 0; }

test_ok "default router table name" router_firewall_validate_table_name hostkit_router
test_not_ok "unsafe table name rejected" router_firewall_validate_table_name 'bad name'
test_not_ok "same LAN and WAN rejected" router_firewall_render eth0 eth0

rules="$(router_firewall_render eth1 eth0)"
printf '%s\n' "$rules" | grep -Fq 'ct state invalid drop' || test_fail "invalid state drop rendered"
printf '%s\n' "$rules" | grep -Fq 'ct state established,related accept' || test_fail "stateful return rule rendered"
printf '%s\n' "$rules" | grep -Fq 'iifname "eth1" oifname "eth0" accept' || test_fail "LAN forward rule rendered"
printf '%s\n' "$rules" | grep -Fq 'oifname "eth0" masquerade' || test_fail "NAT44 rule rendered"
test_pass "router forwarding and NAT policy rendered"
