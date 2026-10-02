source "$ROOT_DIR/debian/modules/networkd.sh"

tmp="$(mktemp)"
: >"$tmp"

mock_begin
mock_command systemd-analyze 'exit 0'
mock_command networkctl 'test "$1" = reload'
mock_command systemctl 'test "$*" = "is-active --quiet systemd-networkd.service"'
test_ok "network file validator success" networkd_validate_network_file "$tmp"
test_ok "networkd reload success" networkd_reload
test_ok "networkd active state" networkd_is_active
mock_end

mock_begin
mock_command systemd-analyze 'exit 1'
mock_command networkctl 'exit 1'
mock_command systemctl 'exit 1'
test_not_ok "network file validator failure propagated" networkd_validate_network_file "$tmp"
test_not_ok "networkd reload failure propagated" networkd_reload
test_not_ok "networkd inactive state propagated" networkd_is_active
mock_end

rm -f "$tmp"
