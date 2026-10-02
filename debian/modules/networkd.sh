# systemd-networkd mechanisms.

networkd_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] &&
        IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

networkd_validate_network_file() {
    local path="$1"
    [ -r "$path" ] || return 1

    # systemd-analyze verify validates unit files, not .network files.
    # Keep validation conservative here: generated networkd files are
    # structurally tested by HostKit and runtime-verified after apply.
    grep -Eq '^\[Match\]$' "$path" &&
        grep -Eq '^\[Network\]$' "$path"
}

networkd_install_network_file() {
    local name="$1"
    local source_file="$2"
    local dir="${HOSTKIT_NETWORKD_DIR:-/etc/systemd/network}"
    local path="$dir/$name"
    local tmp

    case "$name" in
        *.network) ;;
        *) die "networkd target must end in .network: $name"; return 1 ;;
    esac
    [ -r "$source_file" ] || { die "networkd source file is not readable: $source_file"; return 1; }
    networkd_validate_network_file "$source_file" || { die "Invalid networkd configuration: $source_file"; return 1; }

    mkdir -p "$dir" || return 1
    tmp="$(mktemp)"
    {
        printf '%s\n' '# Managed by HostKit. Do not edit manually.'
        cat "$source_file"
    } >"$tmp"

    if [ -e "$path" ] && ! networkd_hostkit_owned "$path"; then
        rm -f "$tmp"
        die "Refusing to overwrite networkd file not owned by HostKit: $path"
        return 1
    fi

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi

    install -m 0644 "$tmp" "$path" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
}

networkd_reload() {
    networkctl reload
}

networkd_is_active() {
    systemctl is-active --quiet systemd-networkd.service
}
