# Network inspection mechanisms.

network_detect_uplink() {
    local routes
    routes="$(ip -4 route show default 2>/dev/null | awk '$1 == "default" {for (i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}' | sort -u)"
    [ -n "$routes" ] || return 1
    [ "$(printf '%s\n' "$routes" | wc -l)" -eq 1 ] || return 2
    printf '%s\n' "$routes"
}

network_interface_exists() {
    ip link show dev "$1" >/dev/null 2>&1
}

network_validate_interface_name() {
    local value="$1"
    [ -n "$value" ] && [ "${#value}" -le 15 ] && printf '%s' "$value" | grep -Eq '^[A-Za-z0-9_.:-]+$'
}

network_ipv4_address_present() {
    local interface="$1" address="$2"
    ip -4 addr show dev "$interface" 2>/dev/null | grep -Fq "inet $address "
}
