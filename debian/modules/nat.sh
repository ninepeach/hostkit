# NAT44 mechanisms.

nat_validate_wan() {
    network_validate_interface_name "$1" && network_interface_exists "$1"
}

nat_render_masquerade_rule() {
    local wan="$1"
    nat_validate_wan "$wan" || { die "Invalid WAN interface: $wan"; return 1; }
    printf 'oifname "%s" masquerade\n' "$wan"
}
