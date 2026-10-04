# Alpine ROUTER nftables policy renderer.

router_firewall_validate_interface_name() {
    network_validate_interface_name "$1"
}

router_firewall_render_unchecked() {
    local lan="$1" wan="$2" second_lan="${3:-}"
    router_firewall_validate_interface_name "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    router_firewall_validate_interface_name "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    [ "$lan" != "$wan" ] || { die "LAN and WAN interfaces must be different."; return 1; }
    if [ -n "$second_lan" ]; then
        router_firewall_validate_interface_name "$second_lan" || { die "Invalid SECOND_LAN interface: $second_lan"; return 1; }
        [ "$second_lan" != "$wan" ] || { die "SECOND_LAN and WAN interfaces must be different."; return 1; }
        [ "$second_lan" != "$lan" ] || { die "LAN and SECOND_LAN interfaces must be different."; return 1; }
    fi

    cat <<EOF
table inet hostkit_router {
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state invalid drop
        ct state established,related accept
        iifname "$lan" oifname "$wan" accept
EOF
    if [ -n "$second_lan" ]; then
        cat <<EOF
        iifname "$second_lan" oifname "$wan" accept
EOF
    fi
    cat <<EOF
    }
}
table ip hostkit_router_nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "$wan" masquerade
    }
}
EOF
}

router_firewall_render_pppoe_unchecked() {
    local lan="$1" wan="$2" second_lan="${3:-}"
    router_firewall_validate_interface_name "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    router_firewall_validate_interface_name "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    [ "$lan" != "$wan" ] || { die "LAN and WAN interfaces must be different."; return 1; }
    if [ -n "$second_lan" ]; then
        router_firewall_validate_interface_name "$second_lan" || { die "Invalid SECOND_LAN interface: $second_lan"; return 1; }
        [ "$second_lan" != "$wan" ] || { die "SECOND_LAN and WAN interfaces must be different."; return 1; }
        [ "$second_lan" != "$lan" ] || { die "LAN and SECOND_LAN interfaces must be different."; return 1; }
    fi

    cat <<EOF
table inet hostkit_router {
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state invalid drop
        ct state established,related accept
        oifname "$wan" tcp flags syn tcp option maxseg size set rt mtu
        iifname "$lan" oifname "$wan" accept
EOF
    if [ -n "$second_lan" ]; then
        cat <<EOF
        iifname "$second_lan" oifname "$wan" accept
EOF
    fi
    cat <<EOF
    }
}
table ip hostkit_router_nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "$wan" masquerade
    }
}
EOF
}

router_firewall_render() {
    local lan="$1" wan="$2" second_lan="${3:-}"
    network_interface_exists "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    network_interface_exists "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    if [ -n "$second_lan" ]; then
        network_interface_exists "$second_lan" || { die "Invalid SECOND_LAN interface: $second_lan"; return 1; }
    fi
    router_firewall_render_unchecked "$lan" "$wan" "$second_lan"
}

router_firewall_render_pppoe() {
    local lan="$1" wan="$2" second_lan="${3:-}"
    network_interface_exists "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    network_interface_exists "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    if [ -n "$second_lan" ]; then
        network_interface_exists "$second_lan" || { die "Invalid SECOND_LAN interface: $second_lan"; return 1; }
    fi
    router_firewall_render_pppoe_unchecked "$lan" "$wan" "$second_lan"
}
