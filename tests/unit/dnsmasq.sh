source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/dnsmasq.sh"

tmp="$(mktemp)"
printf '%s\n' 'interface=eth1' >"$tmp"

mock_begin
mock_command dnsmasq 'exit 0'
mock_command systemctl 'case "$*" in "reload dnsmasq.service"|"is-active --quiet dnsmasq.service") exit 0 ;; *) exit 1 ;; esac'
test_ok "valid config accepted" dnsmasq_validate "$tmp"
test_ok "reload propagates success" dnsmasq_reload
test_ok "active state propagates success" dnsmasq_is_active

tmpdir="$(mktemp -d)"
export HOSTKIT_DNSMASQ_PATH="$tmpdir/90-hostkit-router.conf"
test_ok "managed dnsmasq config installed" dnsmasq_install_config "$tmp"
test_ok "installed dnsmasq config is marked owned" dnsmasq_hostkit_owned "$HOSTKIT_DNSMASQ_PATH"
test_ok "dnsmasq install idempotent" dnsmasq_install_config "$tmp"
printf '%s\n' '# administrator file' >"$HOSTKIT_DNSMASQ_PATH"
test_not_ok "foreign dnsmasq file preserved" dnsmasq_install_config "$tmp"
test_eq "foreign dnsmasq content unchanged" "# administrator file" "$(cat "$HOSTKIT_DNSMASQ_PATH")"
unset HOSTKIT_DNSMASQ_PATH
rm -rf "$tmpdir"
mock_end

mock_begin
mock_command dnsmasq 'exit 1'
mock_command systemctl 'exit 1'
test_not_ok "invalid config rejected" dnsmasq_validate "$tmp"
test_not_ok "reload failure propagated" dnsmasq_reload
test_not_ok "inactive state propagated" dnsmasq_is_active
mock_end

rm -f "$tmp"
