# HostKit ROUTER product definition.
# v0.1 implements the safe preserve-existing-uplink path.
# Active DHCP/PPPoE ownership remains gated until Debian 13 runtime validation is complete.

MODULES=(
    core
    network
    forwarding
    nftables
    nat
    router-firewall
)

hostkit_main() {
    require_root
    require_debian_13
    require_command ip sysctl nft grep awk sort wc mktemp

    [ "$#" -eq 0 ] || {
        die "Configured WAN/LAN ownership is not yet enabled in ROUTER v0.1; run without arguments to preserve the existing uplink."
        return 1
    }

    local uplink rc=0
    uplink="$(network_detect_uplink)" || rc=$?
    case "$rc" in
        0) ;;
        2) die "Multiple IPv4 default-route uplinks detected; refusing to guess."; return 1 ;;
        *) die "No unambiguous IPv4 default-route uplink detected."; return 1 ;;
    esac

    # Persist only the IPv4 setting ROUTER currently owns. Do not disable an
    # already-enabled IPv6 forwarding path while IPv6 ownership remains unreleased.
    local ipv6=0
    forwarding_ipv6_enabled && ipv6=1
    forwarding_write_persistent 1 "$ipv6"
    forwarding_set_ipv4 1
    forwarding_ipv4_enabled || { die "IPv4 forwarding could not be enabled."; return 1; }

    log_ok "IPv4 forwarding enabled."
    log_info "Detected preserved uplink: $uplink"
    log_warn "ROUTER v0.1 does not yet take ownership of LAN, DHCP, PPPoE, or persistent nftables policy."
    log_ok "Safe preserve-existing-uplink preparation completed."
}
