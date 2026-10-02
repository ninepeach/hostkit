# ROUTER nftables policy rendering.
# Product policy lives here rather than in the NAT mechanism.

router_firewall_validate_table_name() {
    local value="$1"
    [ -n "$value" ] && printf '%s' "$value" | grep -Eq '^[A-Za-z0-9_.:-]+$'
}

router_firewall_render() {
    local lan="$1" wan="$2"
    local filter_table="${3:-hostkit_router}"
    local nat_table="${4:-hostkit_router_nat}"

    network_validate_interface_name "$lan" && network_interface_exists "$lan" ||
        { die "Invalid LAN interface: $lan"; return 1; }
    network_validate_interface_name "$wan" && network_interface_exists "$wan" ||
        { die "Invalid WAN interface: $wan"; return 1; }
    [ "$lan" != "$wan" ] || { die "LAN and WAN interfaces must be different."; return 1; }
    router_firewall_validate_table_name "$filter_table" &&
        router_firewall_validate_table_name "$nat_table" ||
        { die "Invalid nftables table name."; return 1; }

    cat <<EOF
table inet $filter_table {
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state invalid drop
        ct state established,related accept
        iifname "$lan" oifname "$wan" accept
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
