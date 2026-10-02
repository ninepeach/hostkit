source "$ROOT_DIR/debian/modules/dnsmasq.sh"

tmp="$(mktemp)"
: >"$tmp"

mock_begin
mock_command dnsmasq 'case "$*" in *--test*) exit 0 ;; *) exit 1 ;; esac'
mock_command systemctl 'case "$*" in "reload dnsmasq.service"|"is-active --quiet dnsmasq.service") exit 0 ;; *) exit 1 ;; esac'
test_ok "valid config accepted" dnsmasq_validate "$tmp"
test_ok "reload propagates success" dnsmasq_reload
test_ok "active state propagates success" dnsmasq_is_active
mock_end

mock_begin
mock_command dnsmasq 'exit 1'
mock_command systemctl 'exit 1'
test_not_ok "invalid config rejected" dnsmasq_validate "$tmp"
test_not_ok "reload failure propagated" dnsmasq_reload
test_not_ok "inactive state propagated" dnsmasq_is_active
mock_end

rm -f "$tmp"
