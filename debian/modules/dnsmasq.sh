# dnsmasq mechanisms.

dnsmasq_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] &&
        IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

dnsmasq_validate() {
    dnsmasq --test --conf-file="$1" >/dev/null 2>&1
}

dnsmasq_install_config() {
    local source_file="$1"
    local path="${HOSTKIT_DNSMASQ_PATH:-/etc/dnsmasq.d/90-hostkit-router.conf}"
    local tmp

    [ -r "$source_file" ] || { die "dnsmasq source file is not readable: $source_file"; return 1; }
    dnsmasq_validate "$source_file" || { die "Invalid dnsmasq configuration."; return 1; }

    tmp="$(mktemp)"
    {
        printf '%s\n' '# Managed by HostKit. Do not edit manually.'
        cat "$source_file"
    } >"$tmp"

    if [ -e "$path" ] && ! dnsmasq_hostkit_owned "$path"; then
        rm -f "$tmp"
        die "Refusing to overwrite dnsmasq file not owned by HostKit: $path"
        return 1
    fi

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi

    install -m 0644 "$tmp" "$path" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
    dnsmasq_validate "$path"
}

dnsmasq_reload() {
    systemctl reload dnsmasq.service
}

dnsmasq_is_active() {
    systemctl is-active --quiet dnsmasq.service
}
