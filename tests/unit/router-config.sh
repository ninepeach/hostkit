source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network.sh"
source "$ROOT_DIR/debian/modules/router-config.sh"

tmp="$(mktemp)"
cat >"$tmp" <<'EOF'
UPLINK=eth0
UPLINK_MODE=dhcp
LAN=eth1
LAN_ADDRESS=192.168.10.1/24
DHCP_RANGE=192.168.10.100-192.168.10.200
EOF
test_ok "parse valid router config" router_config_parse "$tmp"
test_ok "validate DHCP router config" router_config_validate
test_eq "UPLINK parsed" eth0 "$UPLINK"
test_eq "LAN parsed" eth1 "$LAN"

cat >"$tmp" <<'EOF'
UNKNOWN=value
EOF
test_not_ok "unknown key rejected" router_config_parse "$tmp"
rm -f "$tmp"

cat >"$tmp" <<'EOF'
UPLINK=eth0
UPLINK=eth1
EOF
test_not_ok "duplicate key rejected" router_config_parse "$tmp"

cat >"$tmp" <<'EOF'
UPLINK=eth0
UPLINK_MODE=dhcp
LAN=eth0
EOF
router_config_parse "$tmp"
test_not_ok "same WAN and LAN rejected" router_config_validate
