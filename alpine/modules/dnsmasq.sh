# Alpine dnsmasq managed configuration.

dnsmasq_render() {
    local lan="$1" lan_address="$2" range="$3" gateway="${lan_address%/*}"
    local first="${range%%-*}" last="${range#*-}"
    cat <<EOF
# Managed by HostKit. Do not edit manually.
interface=$lan
bind-interfaces
dhcp-range=$first,$last,12h
dhcp-option=option:router,$gateway
dhcp-option=option:dns-server,$gateway
EOF
}

dnsmasq_validate() { dnsmasq --test --conf-file="$1" >/dev/null 2>&1; }

dnsmasq_install() {
    local source="$1" path="${HOSTKIT_DNSMASQ_PATH:-/etc/dnsmasq.d/90-hostkit-router.conf}"
    dnsmasq_validate "$source" || { die "Invalid dnsmasq configuration."; return 1; }
    mkdir -p "$(dirname "$path")"
    if [ -e "$path" ] && ! grep -qx '# Managed by HostKit. Do not edit manually.' "$path"; then
        die "Refusing to overwrite dnsmasq file not owned by HostKit: $path"; return 1
    fi
    install -m 0644 "$source" "$path"
}
