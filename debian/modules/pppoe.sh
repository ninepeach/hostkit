# PPPoE inspection mechanisms.

pppoe_validate_user() {
    local value="$1"
    [ -n "$value" ] && ! printf '%s' "$value" | grep -q '[[:cntrl:]]'
}

pppoe_validate_secret_file() {
    local path="$1"
    [ -f "$path" ] && [ -r "$path" ] && [ ! -L "$path" ]
}

pppoe_is_active() {
    local interface="${1:-ppp0}"
    ip link show dev "$interface" >/dev/null 2>&1 &&
        ip -4 addr show dev "$interface" | grep -q 'inet '
}
