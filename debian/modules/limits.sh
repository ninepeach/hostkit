# Login-session resource-limit mechanisms.

limits_configure_nofile() {
    local value="${1:-65535}"
    local path="${HOSTKIT_LIMITS_PATH:-/etc/security/limits.d/90-hostkit.conf}"
    local tmp

    case "$value" in
        ''|*[!0-9]*)
            die "Invalid nofile limit: $value"
            return 1
            ;;
    esac

    if [ "$value" -lt 1024 ]; then
        die "nofile limit is unexpectedly low: $value"
        return 1
    fi

    tmp="$(mktemp)"
    cat >"$tmp" <<EOF
# Managed by HostKit. Do not edit manually.
* soft nofile $value
* hard nofile $value
EOF

    if [ -e "$path" ]; then
        local first=
        IFS= read -r first <"$path" || true
        if [ "$first" != "# Managed by HostKit. Do not edit manually." ]; then
            rm -f "$tmp"
            die "Refusing to overwrite limits file not owned by HostKit: $path"
            return 1
        fi
    fi

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi

    if ! install -m 0644 "$tmp" "$path"; then
        rm -f "$tmp"
        return 1
    fi
    rm -f "$tmp"
}

limits_validate_nofile() {
    local value="${1:-65535}"
    local path="${HOSTKIT_LIMITS_PATH:-/etc/security/limits.d/90-hostkit.conf}"

    [ -r "$path" ] || return 1
    grep -Fqx "* soft nofile $value" "$path" &&
        grep -Fqx "* hard nofile $value" "$path"
}
