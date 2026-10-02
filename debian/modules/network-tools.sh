# Network and DNS preflight mechanisms.

network_default_route_available() {
    ip route show default 2>/dev/null | grep -q '^default '
}

network_dns_available() {
    getent ahosts deb.debian.org >/dev/null 2>&1
}

network_require_connectivity() {
    if ! network_default_route_available; then
        die "No IPv4 default route is available."
        return 1
    fi

    if ! network_dns_available; then
        die "DNS resolution is not working."
        return 1
    fi
}
