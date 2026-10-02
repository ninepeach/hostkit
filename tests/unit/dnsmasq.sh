source "$ROOT_DIR/debian/modules/dnsmasq.sh"

mock_begin
mock_command dnsmasq 'exit 0'
tmp="$(mktemp)"
: >"$tmp"
test_ok "dnsmasq validator propagates success" dnsmasq_validate "$tmp"
rm -f "$tmp"
mock_end
