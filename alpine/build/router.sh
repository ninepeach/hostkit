# HostKit Alpine ROUTER product definition.
# Live configured takeover remains gated on Alpine VM validation.

MODULES=(
    core
    network
    dhcp
    pppoe
    router-config
    network-config
    forwarding
    nftables
    router-firewall
    router-nftables
    dnsmasq
)

hostkit_main() {
    require_root
    require_alpine
    require_command ip sysctl nft grep awk mktemp install cmp

    if [ "$#" -eq 0 ]; then
        local uplink rc=0 ipv6=0
        uplink="$(network_detect_uplink)" || rc=$?
        case "$rc" in
            0) ;;
            2) die "Multiple or missing IPv4 default-route uplinks; refusing to guess."; return 1 ;;
            *) die "Unable to detect uplink."; return 1 ;;
        esac
        forwarding_ipv6_enabled && ipv6=1
        forwarding_write_persistent 1 "$ipv6"
        forwarding_set_ipv4 1
        forwarding_ipv4_enabled || { die "IPv4 forwarding could not be enabled."; return 1; }
        log_ok "IPv4 forwarding enabled."
        log_info "Detected preserved uplink: $uplink"
        log_warn "No configuration supplied; network ownership was not changed."
        log_ok "Alpine ROUTER preserve-existing-uplink preparation completed."
        return 0
    fi

    [ "$#" -eq 2 ] && [ "$1" = "--check" ] || {
        die "Usage: alpine-router.sh [--check ROUTER_CONFIG]"
        return 2
    }

    router_config_parse "$2"
    router_config_validate

    local d network_file dnsmasq_file nft_file wan_for_firewall
    d="$(mktemp -d)"
    network_file="$d/interfaces"
    dnsmasq_file="$d/dnsmasq.conf"
    nft_file="$d/router.nft"

    if [ "$UPLINK_MODE" = dhcp ]; then
        network_config_render_dhcp "$UPLINK" "$LAN" "$LAN_ADDRESS" >"$network_file"
        wan_for_firewall="$UPLINK"
    else
        network_config_render_pppoe_lan "$LAN" "$LAN_ADDRESS" >"$network_file"
        pppoe_render_peer "$UPLINK" "$PPPOE_USER" >"$d/pppoe-peer"
        wan_for_firewall=ppp0
    fi
    dnsmasq_render "$LAN" "$LAN_ADDRESS" "$DHCP_RANGE" >"$dnsmasq_file"

    # ppp0 may not exist before PPPoE is started, so render validation only
    # requires interface syntax for that future runtime interface.
    if [ "$UPLINK_MODE" = pppoe ]; then
        router_firewall_render_pppoe_unchecked "$LAN" "$wan_for_firewall" >"$nft_file"
    else
        router_firewall_render "$LAN" "$wan_for_firewall" >"$nft_file"
    fi

    require_command dnsmasq
    dnsmasq_validate "$dnsmasq_file" || { rm -rf "$d"; die "Generated dnsmasq configuration is invalid."; return 1; }
    nftables_validate_file "$nft_file" || { rm -rf "$d"; die "Generated nftables ruleset is invalid."; return 1; }
    rm -rf "$d"

    log_ok "Router configuration is valid."
    log_info "UPLINK_MODE=$UPLINK_MODE UPLINK=$UPLINK LAN=$LAN LAN_ADDRESS=$LAN_ADDRESS"
    log_warn "Check mode does not write files, restart services, or change live networking."
}
