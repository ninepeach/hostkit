# chrony mechanisms.

chrony_ensure_running() {
    systemctl enable --now chrony.service
}

chrony_validate() {
    if ! systemctl is-active --quiet chrony.service; then
        die "chrony.service is not active."
        return 1
    fi

    local leap_status
    leap_status="$(chronyc tracking 2>/dev/null | awk -F: '/^Leap status[[:space:]]*:/ {sub(/^[[:space:]]+/, "", $2); print $2}')"

    if [ "$leap_status" = "Normal" ]; then
        return 0
    fi

    log_warn "chrony is running but synchronization is not yet confirmed."
    return 2
}
