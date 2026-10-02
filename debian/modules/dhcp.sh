# DHCPv4 value validation mechanisms.

dhcp_validate_ipv4() {
    local value="$1"
    local a b c d extra
    IFS=. read -r a b c d extra <<EOF
$value
EOF
    [ -z "${extra:-}" ] || return 1
    for octet in "$a" "$b" "$c" "$d"; do
        case "$octet" in ''|*[!0-9]*) return 1 ;; esac
        [ "$octet" -ge 0 ] && [ "$octet" -le 255 ] || return 1
    done
}

dhcp_validate_range() {
    local value="$1"
    case "$value" in *-*) ;; *) return 1 ;; esac
    local first="${value%%-*}" last="${value#*-}"
    [ "$first" != "$last" ] || return 1
    dhcp_validate_ipv4 "$first" && dhcp_validate_ipv4 "$last"
}
