# Alpine ROUTER nftables policy renderer.

router_firewall_validate_interface_name() {
    network_validate_interface_name "$1"
}

router_firewall_render_unchecked() {
    local lan="$1" wan="$2"
    router_firewall_validate_interface_name "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    router_firewall_validate_interface_name "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    [ "$lan" != "$wan" ] || { die "LAN and WAN interfaces must be different."; return 1; }

    cat <<EOF
table inet hostkit_router {
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state invalid drop
        ct state established,related accept
        iifname "$lan" oifname "$wan" accept
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
    local lan="$1" wan="$2"
    router_firewall_validate_interface_name "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    router_firewall_validate_interface_name "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    [ "$lan" != "$wan" ] || { die "LAN and WAN interfaces must be different."; return 1; }

    cat <<EOF
table inet hostkit_router {
    chain forward {
        type filter hook forward priority 0; policy drop;
        ct state invalid drop
        ct state established,related accept
        oifname "$wan" tcp flags syn tcp option maxseg size set rt mtu
        iifname "$lan" oifname "$wan" accept
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
    local lan="$1" wan="$2"
    network_interface_exists "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    network_interface_exists "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    router_firewall_render_unchecked "$lan" "$wan"
}

router_firewall_render_pppoe() {
    local lan="$1" wan="$2"
    network_interface_exists "$lan" || { die "Invalid LAN interface: $lan"; return 1; }
    network_interface_exists "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    router_firewall_render_pppoe_unchecked "$lan" "$wan"
}
