# Alpine forwarding mechanisms.

forwarding_ipv4_enabled() { [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = 1 ]; }
forwarding_ipv6_enabled() { [ "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" = 1 ]; }

forwarding_set_ipv4() { sysctl -q -w net.ipv4.ip_forward="$1" >/dev/null; }

forwarding_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] && IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

forwarding_write_persistent() {
    local ipv4="$1" ipv6="$2"
    local path="${HOSTKIT_SYSCTL_FILE:-/etc/sysctl.d/90-hostkit-router.conf}"
    case "$ipv4:$ipv6" in 0:0|0:1|1:0|1:1) ;; *) die "Invalid forwarding state."; return 1 ;; esac

    if [ -e "$path" ] && ! forwarding_hostkit_owned "$path"; then
        die "Refusing to overwrite sysctl file not owned by HostKit: $path"
        return 1
    fi

    mkdir -p "$(dirname "$path")"
    local tmp
    tmp="$(mktemp)"
    {
        printf '# Managed by HostKit. Do not edit manually.\n'
        printf 'net.ipv4.ip_forward = %s\n' "$ipv4"
        printf 'net.ipv6.conf.all.forwarding = %s\n' "$ipv6"
    } >"$tmp"

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then rm -f "$tmp"; return 0; fi
    install -m 0644 "$tmp" "$path"
    rm -f "$tmp"
}
