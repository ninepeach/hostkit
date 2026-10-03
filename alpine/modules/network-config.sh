# Alpine ifupdown-ng managed LAN configuration.

network_config_render() {
    local uplink="$1" lan="$2" lan_address="$3"
    cat <<EOF
# Managed by HostKit. Do not edit manually.
auto $uplink
iface $uplink inet dhcp

auto $lan
iface $lan
    address $lan_address
EOF
}

network_config_install() {
    local source="$1" path="${HOSTKIT_INTERFACES_PATH:-/etc/network/interfaces.d/90-hostkit-router}"
    [ -r "$source" ] || return 1
    mkdir -p "$(dirname "$path")"
    if [ -e "$path" ] && ! grep -qx '# Managed by HostKit. Do not edit manually.' "$path"; then
        die "Refusing to overwrite network file not owned by HostKit: $path"; return 1
    fi
    install -m 0644 "$source" "$path"
}
