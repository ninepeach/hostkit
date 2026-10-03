# Alpine DHCPv4 validation mechanisms.

dhcp_validate_ipv4() {
    local value="$1" a b c d extra octet n
    IFS=. read -r a b c d extra <<EOF
$value
EOF
    [ -z "${extra:-}" ] || return 1
    for octet in "$a" "$b" "$c" "$d"; do
        case "$octet" in ''|*[!0-9]*) return 1 ;; esac
        [ "${#octet}" -eq 1 ] || [ "${octet#0}" = "$octet" ] || return 1
        n=$((10#$octet)); [ "$n" -le 255 ] || return 1
    done
}

dhcp_validate_ipv4_cidr() {
    local value="$1" address prefix
    case "$value" in */*) address="${value%/*}"; prefix="${value##*/}" ;; *) return 1 ;; esac
    dhcp_validate_ipv4 "$address" || return 1
    case "$prefix" in ''|*[!0-9]*) return 1 ;; esac
    [ "$((10#$prefix))" -le 30 ]
}

dhcp_validate_range() {
    local value="$1" first last
    case "$value" in *-*) first="${value%%-*}"; last="${value#*-}" ;; *) return 1 ;; esac
    dhcp_validate_ipv4 "$first" && dhcp_validate_ipv4 "$last" || return 1
    [ "$first" != "$last" ]
}
