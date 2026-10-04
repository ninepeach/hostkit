# Alpine dnsmasq managed configuration.

dnsmasq_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] && IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

dnsmasq_render() {
    local lan="$1" lan_address="$2" range="$3" second_lan="${4:-}" second_lan_address="${5:-}" second_range="${6:-}"
    local gateway="${lan_address%/*}"
    local first="${range%%-*}" last="${range#*-}"
    if [ -z "$second_lan" ]; then
        cat <<EOF
# Managed by HostKit. Do not edit manually.
interface=$lan
bind-interfaces
dhcp-range=$first,$last,12h
dhcp-option=option:router,$gateway
dhcp-option=option:dns-server,$gateway
EOF
        return
    fi

    cat <<EOF
# Managed by HostKit. Do not edit manually.
interface=$lan
interface=$second_lan
bind-interfaces
dhcp-range=set:$lan,$first,$last,12h
dhcp-option=tag:$lan,option:router,$gateway
dhcp-option=tag:$lan,option:dns-server,$gateway
EOF
    gateway="${second_lan_address%/*}"
    first="${second_range%%-*}"; last="${second_range#*-}"
    cat <<EOF
dhcp-range=set:$second_lan,$first,$last,12h
dhcp-option=tag:$second_lan,option:router,$gateway
dhcp-option=tag:$second_lan,option:dns-server,$gateway
EOF
}

dnsmasq_validate() { dnsmasq --test --conf-file="$1" >/dev/null 2>&1; }

dnsmasq_install() {
    local source="$1" path="${HOSTKIT_DNSMASQ_PATH:-/etc/dnsmasq.d/90-hostkit-router.conf}"
    dnsmasq_validate "$source" || { die "Invalid dnsmasq configuration."; return 1; }
    mkdir -p "$(dirname "$path")"
    if [ -e "$path" ] && ! dnsmasq_hostkit_owned "$path"; then
        die "Refusing to overwrite dnsmasq file not owned by HostKit: $path"; return 1
    fi
    if [ -f "$path" ] && cmp -s "$source" "$path"; then return 0; fi
    install -m 0644 "$source" "$path"
}
