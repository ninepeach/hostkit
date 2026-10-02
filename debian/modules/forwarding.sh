# Kernel forwarding mechanisms.

forwarding_ipv4_enabled() {
    [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = "1" ]
}

forwarding_ipv6_enabled() {
    [ "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" = "1" ]
}

forwarding_set_ipv4() {
    local value="$1"
    case "$value" in 0|1) ;; *) die "Invalid IPv4 forwarding value: $value"; return 1 ;; esac
    sysctl -w "net.ipv4.ip_forward=$value" >/dev/null
}

forwarding_set_ipv6() {
    local value="$1"
    case "$value" in 0|1) ;; *) die "Invalid IPv6 forwarding value: $value"; return 1 ;; esac
    sysctl -w "net.ipv6.conf.all.forwarding=$value" >/dev/null
}
