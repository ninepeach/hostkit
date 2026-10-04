# Alpine ifupdown-ng managed network configuration.

network_config_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] && IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

network_config_render_dhcp() {
    local uplink="$1" lan="$2" lan_address="$3" second_lan="${4:-}" second_lan_address="${5:-}"
    cat <<EOF
# Managed by HostKit. Do not edit manually.
auto $uplink
iface $uplink inet dhcp

auto $lan
iface $lan inet static
    address $lan_address
EOF
    if [ -n "$second_lan" ]; then
        cat <<EOF

auto $second_lan
iface $second_lan inet static
    address $second_lan_address
EOF
    fi
}

network_config_render_pppoe_lan() {
    local lan="$1" lan_address="$2" second_lan="${3:-}" second_lan_address="${4:-}"
    cat <<EOF
# Managed by HostKit. Do not edit manually.
auto $lan
iface $lan inet static
    address $lan_address
EOF
    if [ -n "$second_lan" ]; then
        cat <<EOF

auto $second_lan
iface $second_lan inet static
    address $second_lan_address
EOF
    fi
}

network_config_install() {
    local source="$1" path="${HOSTKIT_INTERFACES_PATH:-/etc/network/interfaces.d/90-hostkit-router}"
    [ -r "$source" ] || { die "Network source file is not readable: $source"; return 1; }
    mkdir -p "$(dirname "$path")"
    if [ -e "$path" ] && ! network_config_hostkit_owned "$path"; then
        die "Refusing to overwrite network file not owned by HostKit: $path"; return 1
    fi
    if [ -f "$path" ] && cmp -s "$source" "$path"; then return 0; fi
    install -m 0644 "$source" "$path"
}
