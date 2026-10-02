source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/network.sh"
source "$ROOT_DIR/debian/modules/dhcp.sh"
source "$ROOT_DIR/debian/modules/pppoe.sh"
source "$ROOT_DIR/debian/modules/router-config.sh"

tmp="$(mktemp)"
secret="$(mktemp)"
chmod 600 "$secret"
printf '%s\n' 'secret' >"$secret"

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

cat >"$tmp" <<'EOF'
LAN=eth1
LAN_ADDRESS=192.168.10.1/99
EOF
router_config_parse "$tmp"
test_not_ok "invalid LAN CIDR rejected" router_config_validate

cat >"$tmp" <<'EOF'
LAN=eth1
LAN_ADDRESS=192.168.10.1/24
DHCP_RANGE=192.168.10.200-192.168.10.100
EOF
router_config_parse "$tmp"
test_not_ok "reversed DHCP range rejected" router_config_validate

cat >"$tmp" <<EOF
UPLINK=eth0
UPLINK_MODE=pppoe
PPPOE_USER=user@example.com
PPPOE_SECRET_FILE=$secret
EOF
router_config_parse "$tmp"
test_ok "valid PPPoE config accepted" router_config_validate

cat >"$tmp" <<'EOF'
UPLINK=eth0
UPLINK_MODE=dhcp
PPPOE_USER=user@example.com
EOF
router_config_parse "$tmp"
test_not_ok "PPPoE settings rejected in DHCP mode" router_config_validate

rm -f "$tmp" "$secret"
