# HostKit Alpine ROUTER product definition.
# Initial release is intentionally inspect/preserve oriented.

MODULES=(
    core
    network
    dhcp
    router-config
    network-config
    forwarding
    nftables
    router-firewall
    router-nftables
    dnsmasq
    pppoe
)

hostkit_main() {
    require_root
    require_alpine
    require_command ip sysctl nft grep awk mktemp install

    [ "$#" -eq 0 ] || { die "Alpine ROUTER does not accept configuration arguments yet."; return 1; }

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


    log_warn "LAN, PPPoE, dnsmasq and persistent nftables ownership are not enabled yet."
    log_ok "Alpine ROUTER preserve-existing-uplink preparation completed."
}
