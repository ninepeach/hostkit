# Strict ROUTER KEY=VALUE configuration parser.

router_config_reset() {
    UPLINK=
    UPLINK_MODE=
    LAN=
    LAN_ADDRESS=
    DHCP_RANGE=
    PPPOE_USER=
    PPPOE_SECRET_FILE=
}

router_config_key_allowed() {
    case "$1" in
        UPLINK|UPLINK_MODE|LAN|LAN_ADDRESS|DHCP_RANGE|PPPOE_USER|PPPOE_SECRET_FILE) return 0 ;;
        *) return 1 ;;
    esac
}

router_config_parse() {
    local path="$1"
    [ -r "$path" ] || { die "Router configuration is not readable: $path"; return 1; }
    router_config_reset

    local line key value seen="|"
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|\#*) continue ;; esac
        case "$line" in *=*) ;; *) die "Invalid router configuration record."; return 1 ;; esac
        key="${line%%=*}"
        value="${line#*=}"
        router_config_key_allowed "$key" || { die "Unknown router configuration key: $key"; return 1; }
        case "$seen" in *"|$key|"*) die "Duplicate router configuration key: $key"; return 1 ;; esac
        case "$value" in *$'\n'*|*$'\r'*) die "Invalid router configuration value for $key"; return 1 ;; esac
        seen="${seen}$key|"
        printf -v "$key" '%s' "$value"
    done <"$path"
}

router_config_validate() {
    if [ -n "$UPLINK_MODE" ]; then
        case "$UPLINK_MODE" in dhcp|pppoe) ;; *) die "Invalid UPLINK_MODE: $UPLINK_MODE"; return 1 ;; esac
        [ -n "$UPLINK" ] || { die "UPLINK is required when UPLINK_MODE is set."; return 1; }
    fi

    if [ -n "$UPLINK" ]; then
        network_validate_interface_name "$UPLINK" || { die "Invalid UPLINK: $UPLINK"; return 1; }
    fi

    if [ -n "$LAN" ]; then
        network_validate_interface_name "$LAN" || { die "Invalid LAN: $LAN"; return 1; }
    fi

    if [ -n "$UPLINK" ] && [ -n "$LAN" ] && [ "$UPLINK" = "$LAN" ]; then
        die "UPLINK and LAN must be different interfaces."
        return 1
    fi

    if [ -n "$LAN_ADDRESS" ]; then
        [ -n "$LAN" ] || { die "LAN_ADDRESS requires LAN."; return 1; }
        dhcp_validate_ipv4_cidr "$LAN_ADDRESS" || { die "Invalid LAN_ADDRESS: $LAN_ADDRESS"; return 1; }
    fi

    if [ -n "$DHCP_RANGE" ]; then
        [ -n "$LAN" ] && [ -n "$LAN_ADDRESS" ] || { die "DHCP_RANGE requires LAN and LAN_ADDRESS."; return 1; }
        dhcp_validate_range "$DHCP_RANGE" || { die "Invalid DHCP_RANGE: $DHCP_RANGE"; return 1; }
    fi

    if [ "$UPLINK_MODE" = "pppoe" ]; then
        [ -n "$PPPOE_USER" ] || { die "PPPOE_USER is required for PPPoE."; return 1; }
        [ -n "$PPPOE_SECRET_FILE" ] || { die "PPPOE_SECRET_FILE is required for PPPoE."; return 1; }
        pppoe_validate_user "$PPPOE_USER" || { die "Invalid PPPOE_USER."; return 1; }
        pppoe_validate_secret_file "$PPPOE_SECRET_FILE" || { die "Invalid PPPOE_SECRET_FILE."; return 1; }
    else
        if [ -n "$PPPOE_USER" ] || [ -n "$PPPOE_SECRET_FILE" ]; then
            die "PPPoE settings require UPLINK_MODE=pppoe."
            return 1
        fi
    fi
}
