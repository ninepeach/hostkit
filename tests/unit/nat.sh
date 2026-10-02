source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network.sh"
source "$ROOT_DIR/debian/modules/nat.sh"

network_interface_exists() { return 0; }

test_ok "valid WAN accepted" nat_validate_wan eth0
test_not_ok "invalid WAN rejected" nat_validate_wan "bad interface"
test_eq "masquerade rule rendering" 'oifname "eth0" masquerade' "$(nat_render_masquerade_rule eth0)"
