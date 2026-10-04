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

dhcp_ipv4_to_int() {
    local value="$1" a b c d
    dhcp_validate_ipv4 "$value" || return 1
    IFS=. read -r a b c d <<EOF
$value
EOF
    printf '%u\n' "$(( (10#$a << 24) + (10#$b << 16) + (10#$c << 8) + 10#$d ))"
}

dhcp_range_usable_for_lan() {
    local cidr="$1" range="$2" gateway prefix first last g f l mask network broadcast
    gateway="${cidr%/*}"; prefix="${cidr##*/}"; first="${range%%-*}"; last="${range#*-}"
    g="$(dhcp_ipv4_to_int "$gateway")" || return 1
    f="$(dhcp_ipv4_to_int "$first")" || return 1
    l="$(dhcp_ipv4_to_int "$last")" || return 1
    [ "$f" -lt "$l" ] || return 1
    mask=$(( (0xFFFFFFFF << (32 - 10#$prefix)) & 0xFFFFFFFF ))
    network=$((g & mask)); broadcast=$((network | ((~mask) & 0xFFFFFFFF)))
    [ $((f & mask)) -eq "$network" ] && [ $((l & mask)) -eq "$network" ] || return 1
    [ "$f" -ne "$network" ] && [ "$l" -ne "$broadcast" ] || return 1
    ! { [ "$g" -ge "$f" ] && [ "$g" -le "$l" ]; }
}

dhcp_cidr_network() {
    local cidr="$1" gateway prefix g mask network
    dhcp_validate_ipv4_cidr "$cidr" || return 1
    gateway="${cidr%/*}"; prefix="${cidr##*/}"
    g="$(dhcp_ipv4_to_int "$gateway")" || return 1
    mask=$(( (0xFFFFFFFF << (32 - 10#$prefix)) & 0xFFFFFFFF ))
    network=$((g & mask))
    printf '%u/%s\n' "$network" "$prefix"
}
