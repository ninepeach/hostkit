# NAT44 and ROUTER forwarding policy rendering mechanisms.

nat_validate_wan() {
    network_validate_interface_name "$1" && network_interface_exists "$1"
}

nat_validate_lan() {
    network_validate_interface_name "$1" && network_interface_exists "$1"
}

nat_render_masquerade_rule() {
    local wan="$1"
    nat_validate_wan "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    printf 'oifname "%s" masquerade\n' "$wan"
}

nat_render_router_ruleset() {
    local lan="$1"
    local wan="$2"
    local filter_table="${3:-hostkit_router}"
    local nat_table="${4:-hostkit_router_nat}"

    nat_validate_lan "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    nat_validate_wan "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    [ "$lan" != "$wan" ] || { die "LAN and WAN interfaces must be different."; return 1; }

    case "$filter_table:$nat_table" in
        *[!a-zA-Z0-9_:.-]*) die "Invalid nftables table name."; return 1 ;;
    esac

    cat <<EOF
table inet $filter_table {
    chain forward {
        type filter hook forward priority 0; policy drop;
        iifname "$lan" oifname "$wan" accept
        iifname "$wan" oifname "$lan" ct state established,related accept
    }
}
table ip $nat_table {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "$wan" masquerade
    }
}
EOF
}
