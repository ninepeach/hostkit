# DHCPv4 value validation mechanisms.

dhcp_validate_ipv4() {
    local value="$1"
    local a b c d extra octet n
    IFS=. read -r a b c d extra <<EOF
$value
EOF
    [ -z "${extra:-}" ] || return 1
    for octet in "$a" "$b" "$c" "$d"; do
        case "$octet" in ''|*[!0-9]*) return 1 ;; esac
        [ "${#octet}" -eq 1 ] || [ "${octet#0}" = "$octet" ] || return 1
        n=$((10#$octet))
        [ "$n" -le 255 ] || return 1
    done
}

dhcp_ipv4_to_int() {
    local value="$1" a b c d
    dhcp_validate_ipv4 "$value" || return 1
    IFS=. read -r a b c d <<EOF
$value
EOF
    printf '%u\n' "$(( (10#$a << 24) + (10#$b << 16) + (10#$c << 8) + 10#$d ))"
}

dhcp_validate_range() {
    local value="$1"
    case "$value" in *-*) ;; *) return 1 ;; esac
    local first="${value%%-*}" last="${value#*-}" first_n last_n
    [ "$first" != "$last" ] || return 1
    dhcp_validate_ipv4 "$first" && dhcp_validate_ipv4 "$last" || return 1
    first_n="$(dhcp_ipv4_to_int "$first")" || return 1
    last_n="$(dhcp_ipv4_to_int "$last")" || return 1
    [ "$first_n" -lt "$last_n" ]
}

dhcp_validate_ipv4_cidr() {
    local value="$1" address prefix
    case "$value" in */*) address="${value%/*}"; prefix="${value##*/}" ;; *) return 1 ;; esac
    dhcp_validate_ipv4 "$address" || return 1
    case "$prefix" in ''|*[!0-9]*) return 1 ;; esac
    [ "${#prefix}" -eq 1 ] || [ "${prefix#0}" = "$prefix" ] || return 1
    [ "$((10#$prefix))" -le 32 ]
}

dhcp_cidr_contains_ipv4() {
    local cidr="$1" address="$2" base prefix base_n address_n mask
    dhcp_validate_ipv4_cidr "$cidr" || return 1
    dhcp_validate_ipv4 "$address" || return 1
    base="${cidr%/*}"
    prefix="${cidr##*/}"
    base_n="$(dhcp_ipv4_to_int "$base")" || return 1
    address_n="$(dhcp_ipv4_to_int "$address")" || return 1
    if [ "$prefix" -eq 0 ]; then
        mask=0
    else
        mask=$(( (0xFFFFFFFF << (32 - 10#$prefix)) & 0xFFFFFFFF ))
    fi
    [ $((base_n & mask)) -eq $((address_n & mask)) ]
}

dhcp_range_within_cidr() {
    local cidr="$1" range="$2" first last
    dhcp_validate_ipv4_cidr "$cidr" || return 1
    dhcp_validate_range "$range" || return 1
    first="${range%%-*}"
    last="${range#*-}"
    dhcp_cidr_contains_ipv4 "$cidr" "$first" &&
        dhcp_cidr_contains_ipv4 "$cidr" "$last"
}
