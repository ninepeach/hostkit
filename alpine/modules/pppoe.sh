# Alpine PPPoE peer rendering and inspection.
# Secrets remain external and are never copied into router configuration.

pppoe_validate_user() {
    local user="$1"
    [ -n "$user" ] || return 1
    case "$user" in *$'\n'*|*$'\r'*|*$'\t'*) return 1 ;; esac
    case "$user" in
        *[!A-Za-z0-9._@:+/-]*) return 1 ;;
    esac
}

pppoe_validate_secret_file() {
    [ -f "$1" ] && [ -r "$1" ] && [ ! -L "$1" ]
}

pppoe_render_peer() {
    local uplink="$1" user="$2"
    network_validate_interface_name "$uplink" || return 1
    pppoe_validate_user "$user" || return 1
    cat <<EOF
# Managed by HostKit. Do not edit manually.
user "$user"
plugin pppoe.so $uplink
noipdefault
usepeerdns
defaultroute
persist
noauth
EOF
}

pppoe_is_active() {
    local interface="${1:-ppp0}"
    ip link show dev "$interface" >/dev/null 2>&1 &&
        ip -4 addr show dev "$interface" | grep -q 'inet '
}

pppoe_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] && IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

pppoe_install_peer() {
    local source="$1" path="${HOSTKIT_PPPOE_PEER_PATH:-/etc/ppp/peers/hostkit-router}"
    [ -r "$source" ] || { die "PPPoE peer source is not readable: $source"; return 1; }
    if [ -e "$path" ] && ! pppoe_hostkit_owned "$path"; then
        die "Refusing to overwrite PPPoE peer not owned by HostKit: $path"; return 1
    fi
    mkdir -p "$(dirname "$path")"
    if [ -f "$path" ] && cmp -s "$source" "$path"; then return 0; fi
    install -m 0600 "$source" "$path"
}
