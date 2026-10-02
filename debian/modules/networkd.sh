# systemd-networkd mechanisms.

networkd_validate_network_file() {
    local path="$1"
    [ -r "$path" ] || return 1
    systemd-analyze verify "$path" >/dev/null 2>&1
}

networkd_reload() {
    networkctl reload
}

networkd_is_active() {
    systemctl is-active --quiet systemd-networkd.service
}
