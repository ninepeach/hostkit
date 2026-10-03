# Alpine PPPoE peer rendering and inspection.
# Secrets remain external and are never copied into router configuration.

pppoe_validate_user() {
    [ -n "$1" ] && ! printf '%s' "$1" | grep -q '[[:cntrl:]]'
}

pppoe_validate_secret_file() {
    [ -f "$1" ] && [ -r "$1" ] && [ ! -L "$1" ]
}

pppoe_render_peer() {
    local uplink="$1" user="$2"
    network_validate_interface_name "$uplink" || return 1
    pppoe_validate_user "$user" || return 1
    cat <<EOF
# Managed by HostKit. Do not edit manually.
user "$user"
plugin pppoe.so $uplink
noipdefault
usepeerdns
defaultroute
persist
noauth
EOF
}

pppoe_is_active() {
    local interface="${1:-ppp0}"
    ip link show dev "$interface" >/dev/null 2>&1 &&
        ip -4 addr show dev "$interface" | grep -q 'inet '
}
