source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/networkd.sh"

tmp="$(mktemp)"
cat >"$tmp" <<'EOF'
[Match]
Name=eth1
[Network]
Address=192.168.10.1/24
EOF

test_ok "basic network file accepted" networkd_validate_network_file "$tmp"
printf '%s\n' '[Match]' 'Name=eth1' >"$tmp.bad"
test_not_ok "network file without Network section rejected" networkd_validate_network_file "$tmp.bad"

tmpdir="$(mktemp -d)"
export HOSTKIT_NETWORKD_DIR="$tmpdir"
test_ok "managed network file installed" networkd_install_network_file 90-hostkit-lan.network "$tmp"
test_ok "installed file is marked owned" networkd_hostkit_owned "$tmpdir/90-hostkit-lan.network"
test_ok "managed network install idempotent" networkd_install_network_file 90-hostkit-lan.network "$tmp"
printf '%s\n' '# administrator file' >"$tmpdir/90-hostkit-lan.network"
test_not_ok "foreign network file preserved" networkd_install_network_file 90-hostkit-lan.network "$tmp"
test_eq "foreign network content unchanged" "# administrator file" "$(cat "$tmpdir/90-hostkit-lan.network")"
test_not_ok "non-network suffix rejected" networkd_install_network_file hostkit.conf "$tmp"

mock_begin
mock_command networkctl 'test "$1" = reload'
mock_command systemctl 'test "$*" = "is-active --quiet systemd-networkd.service"'
test_ok "networkd reload success" networkd_reload
test_ok "networkd active state" networkd_is_active
mock_end

mock_begin
mock_command networkctl 'exit 1'
mock_command systemctl 'exit 1'
test_not_ok "networkd reload failure propagated" networkd_reload
test_not_ok "networkd inactive state propagated" networkd_is_active
mock_end

unset HOSTKIT_NETWORKD_DIR
rm -rf "$tmpdir"
rm -f "$tmp" "$tmp.bad"
