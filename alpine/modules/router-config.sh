# Strict Alpine ROUTER KEY=VALUE parser.

router_config_reset() {
    UPLINK=; UPLINK_MODE=; LAN=; LAN_ADDRESS=; DHCP_RANGE=
    SECOND_LAN=; SECOND_LAN_ADDRESS=; SECOND_DHCP_RANGE=
    PPPOE_USER=; PPPOE_SECRET_FILE=
}

router_config_parse() {
    local path="$1" line key value seen="|"
    [ -r "$path" ] || { die "Router configuration is not readable: $path"; return 1; }
    router_config_reset
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|\#*) continue ;; esac
        case "$line" in *=*) ;; *) die "Invalid router configuration record."; return 1 ;; esac
        key="${line%%=*}"; value="${line#*=}"
        case "$key" in
            UPLINK|UPLINK_MODE|LAN|LAN_ADDRESS|DHCP_RANGE|SECOND_LAN|SECOND_LAN_ADDRESS|SECOND_DHCP_RANGE|PPPOE_USER|PPPOE_SECRET_FILE) ;;
            *) die "Unknown router configuration key: $key"; return 1 ;;
        esac
        case "$seen" in *"|$key|"*) die "Duplicate router configuration key: $key"; return 1 ;; esac
        case "$value" in *$'\n'*|*$'\r'*) die "Invalid router configuration value for $key"; return 1 ;; esac
        seen="${seen}$key|"; printf -v "$key" '%s' "$value"
    done <"$path"
}

router_config_validate() {
    local lan_network second_lan_network
    case "$UPLINK_MODE" in dhcp|pppoe) ;; *) die "UPLINK_MODE must be dhcp or pppoe."; return 1 ;; esac
    network_interface_exists "$UPLINK" || { die "Invalid UPLINK: $UPLINK"; return 1; }
    network_interface_exists "$LAN" || { die "Invalid LAN: $LAN"; return 1; }
    [ "$UPLINK" != "$LAN" ] || { die "UPLINK and LAN must be different."; return 1; }
    dhcp_validate_ipv4_cidr "$LAN_ADDRESS" || { die "Invalid LAN_ADDRESS."; return 1; }
    dhcp_validate_range "$DHCP_RANGE" || { die "Invalid DHCP_RANGE."; return 1; }
    dhcp_range_usable_for_lan "$LAN_ADDRESS" "$DHCP_RANGE" ||
        { die "DHCP_RANGE is not usable within LAN_ADDRESS."; return 1; }
    lan_network="$(dhcp_cidr_network "$LAN_ADDRESS")" || { die "Invalid LAN_ADDRESS."; return 1; }

    if [ -n "$SECOND_LAN" ] || [ -n "$SECOND_LAN_ADDRESS" ] || [ -n "$SECOND_DHCP_RANGE" ]; then
        [ -n "$SECOND_LAN" ] && [ -n "$SECOND_LAN_ADDRESS" ] && [ -n "$SECOND_DHCP_RANGE" ] ||
            { die "SECOND_LAN requires SECOND_LAN_ADDRESS and SECOND_DHCP_RANGE."; return 1; }
        network_interface_exists "$SECOND_LAN" || { die "Invalid SECOND_LAN: $SECOND_LAN"; return 1; }
        [ "$SECOND_LAN" != "$UPLINK" ] || { die "UPLINK and SECOND_LAN must be different."; return 1; }
        [ "$SECOND_LAN" != "$LAN" ] || { die "LAN and SECOND_LAN must be different."; return 1; }
        dhcp_validate_ipv4_cidr "$SECOND_LAN_ADDRESS" || { die "Invalid SECOND_LAN_ADDRESS."; return 1; }
        dhcp_validate_range "$SECOND_DHCP_RANGE" || { die "Invalid SECOND_DHCP_RANGE."; return 1; }
        dhcp_range_usable_for_lan "$SECOND_LAN_ADDRESS" "$SECOND_DHCP_RANGE" ||
            { die "SECOND_DHCP_RANGE is not usable within SECOND_LAN_ADDRESS."; return 1; }
        second_lan_network="$(dhcp_cidr_network "$SECOND_LAN_ADDRESS")" ||
            { die "Invalid SECOND_LAN_ADDRESS."; return 1; }
        [ "$lan_network" != "$second_lan_network" ] ||
            { die "LAN_ADDRESS and SECOND_LAN_ADDRESS must use different networks."; return 1; }
    fi

    if [ "$UPLINK_MODE" = pppoe ]; then
        pppoe_validate_user "$PPPOE_USER" || { die "Invalid PPPOE_USER."; return 1; }
        pppoe_validate_secret_file "$PPPOE_SECRET_FILE" || { die "Invalid PPPOE_SECRET_FILE."; return 1; }
    elif [ -n "$PPPOE_USER" ] || [ -n "$PPPOE_SECRET_FILE" ]; then
        die "PPPoE settings require UPLINK_MODE=pppoe."
        return 1
    fi
}
