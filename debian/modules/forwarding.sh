# Kernel forwarding mechanisms.

forwarding_ipv4_enabled() {
    [ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" = "1" ]
}

forwarding_ipv6_enabled() {
    [ "$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)" = "1" ]
}

forwarding_validate_value() {
    case "$1" in 0|1) return 0 ;; *) return 1 ;; esac
}

forwarding_set_ipv4() {
    local value="$1"
    forwarding_validate_value "$value" || { die "Invalid IPv4 forwarding value: $value"; return 1; }
    sysctl -w "net.ipv4.ip_forward=$value" >/dev/null
}

forwarding_set_ipv6() {
    local value="$1"
    forwarding_validate_value "$value" || { die "Invalid IPv6 forwarding value: $value"; return 1; }
    sysctl -w "net.ipv6.conf.all.forwarding=$value" >/dev/null
}

forwarding_write_persistent() {
    local ipv4="$1"
    local ipv6="$2"
    local path="${HOSTKIT_SYSCTL_PATH:-/etc/sysctl.d/90-hostkit-router.conf}"
    local tmp

    forwarding_validate_value "$ipv4" || { die "Invalid IPv4 forwarding value: $ipv4"; return 1; }
    forwarding_validate_value "$ipv6" || { die "Invalid IPv6 forwarding value: $ipv6"; return 1; }

    tmp="$(mktemp)"
    cat >"$tmp" <<EOF
# Managed by HostKit. Do not edit manually.
net.ipv4.ip_forward=$ipv4
net.ipv6.conf.all.forwarding=$ipv6
EOF

    if [ -e "$path" ]; then
        local first=
        IFS= read -r first <"$path" || true
        if [ "$first" != "# Managed by HostKit. Do not edit manually." ]; then
            rm -f "$tmp"
            die "Refusing to overwrite sysctl file not owned by HostKit: $path"
            return 1
        fi
        if cmp -s "$tmp" "$path"; then
            rm -f "$tmp"
            return 0
        fi
    fi

    install -m 0644 "$tmp" "$path" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
}
