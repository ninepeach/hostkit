# Strict Alpine ROUTER KEY=VALUE parser.

router_config_reset() { UPLINK=; UPLINK_MODE=; LAN=; LAN_ADDRESS=; DHCP_RANGE=; }

router_config_parse() {
    local path="$1" line key value seen="|"
    [ -r "$path" ] || { die "Router configuration is not readable: $path"; return 1; }
    router_config_reset
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|\#*) continue ;; esac
        case "$line" in *=*) ;; *) die "Invalid router configuration record."; return 1 ;; esac
        key="${line%%=*}"; value="${line#*=}"
        case "$key" in UPLINK|UPLINK_MODE|LAN|LAN_ADDRESS|DHCP_RANGE) ;; *) die "Unknown router configuration key: $key"; return 1 ;; esac
        case "$seen" in *"|$key|"*) die "Duplicate router configuration key: $key"; return 1 ;; esac
        seen="${seen}$key|"; printf -v "$key" '%s' "$value"
    done <"$path"
}

router_config_validate() {
    case "$UPLINK_MODE" in dhcp) ;; *) die "Alpine ROUTER currently supports configured DHCP uplink only."; return 1 ;; esac
    network_interface_exists "$UPLINK" || { die "Invalid UPLINK: $UPLINK"; return 1; }
    network_interface_exists "$LAN" || { die "Invalid LAN: $LAN"; return 1; }
    [ "$UPLINK" != "$LAN" ] || { die "UPLINK and LAN must be different."; return 1; }
    dhcp_validate_ipv4_cidr "$LAN_ADDRESS" || { die "Invalid LAN_ADDRESS."; return 1; }
    dhcp_validate_range "$DHCP_RANGE" || { die "Invalid DHCP_RANGE."; return 1; }
    dhcp_range_usable_for_lan "$LAN_ADDRESS" "$DHCP_RANGE" || { die "DHCP_RANGE is not usable within LAN_ADDRESS."; return 1; }
}
