# Alpine network inspection mechanisms.

network_validate_interface_name() {
    [ -n "$1" ] && printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_.:-]+$'
}

network_interface_exists() {
    network_validate_interface_name "$1" && ip link show dev "$1" >/dev/null 2>&1
}

network_detect_uplink() {
    local routes count
    routes="$(ip -4 route show default 2>/dev/null || true)"
    count="$(printf '%s\n' "$routes" | awk 'NF { n++ } END { print n+0 }')"
    [ "$count" -eq 1 ] || return 2
    printf '%s\n' "$routes" | awk '{ for (i=1;i<=NF;i++) if ($i=="dev") { print $(i+1); exit } }'
}
