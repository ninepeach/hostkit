# Alpine forwarding mechanisms.

forwarding_ipv4_enabled() { [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = 1 ]; }
forwarding_ipv6_enabled() { [ "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" = 1 ]; }

forwarding_set_ipv4() { sysctl -q -w net.ipv4.ip_forward="$1" >/dev/null; }

forwarding_write_persistent() {
    local ipv4="$1" ipv6="$2"
    local path="${HOSTKIT_SYSCTL_FILE:-/etc/sysctl.d/90-hostkit-router.conf}"
    mkdir -p "$(dirname "$path")"
    local tmp
    tmp="$(mktemp)"
    {
        printf '# Managed by HostKit.\n'
        printf 'net.ipv4.ip_forward = %s\n' "$ipv4"
        printf 'net.ipv6.conf.all.forwarding = %s\n' "$ipv6"
    } >"$tmp"
    install -m 0644 "$tmp" "$path"
    rm -f "$tmp"
}
