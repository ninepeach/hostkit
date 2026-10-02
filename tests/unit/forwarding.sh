source "$ROOT_DIR/debian/modules/core.sh"
source "$ROOT_DIR/debian/modules/forwarding.sh"

test_not_ok "invalid IPv4 forwarding rejected" forwarding_set_ipv4 2
test_not_ok "invalid IPv6 forwarding rejected" forwarding_set_ipv6 yes

mock_begin
mock_command sysctl 'case "$*" in "-n net.ipv4.ip_forward") printf "1\n" ;; "-n net.ipv6.conf.all.forwarding") printf "1\n" ;; "-w net.ipv4.ip_forward=1"|"-w net.ipv6.conf.all.forwarding=1") exit 0 ;; *) exit 1 ;; esac'
test_ok "IPv4 enabled state" forwarding_ipv4_enabled
test_ok "IPv6 enabled state" forwarding_ipv6_enabled
test_ok "set IPv4 forwarding" forwarding_set_ipv4 1
test_ok "set IPv6 forwarding" forwarding_set_ipv6 1
mock_end

mock_begin
mock_command sysctl 'exit 1'
test_not_ok "sysctl failure propagated for IPv4" forwarding_set_ipv4 1
test_not_ok "sysctl failure propagated for IPv6" forwarding_set_ipv6 1
mock_end

tmpdir="$(mktemp -d)"
export HOSTKIT_SYSCTL_PATH="$tmpdir/router.conf"
test_ok "persistent forwarding written" forwarding_write_persistent 1 1
test_ok "persistent IPv4 value" grep -Fqx 'net.ipv4.ip_forward=1' "$HOSTKIT_SYSCTL_PATH"
test_ok "persistent IPv6 value" grep -Fqx 'net.ipv6.conf.all.forwarding=1' "$HOSTKIT_SYSCTL_PATH"
test_ok "persistent forwarding idempotent" forwarding_write_persistent 1 1
printf '%s\n' '# admin owned' >"$HOSTKIT_SYSCTL_PATH"
test_not_ok "foreign sysctl file is preserved" forwarding_write_persistent 1 1
test_eq "foreign sysctl content unchanged" "# admin owned" "$(cat "$HOSTKIT_SYSCTL_PATH")"
unset HOSTKIT_SYSCTL_PATH
rm -rf "$tmpdir"
