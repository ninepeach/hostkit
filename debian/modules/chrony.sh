# chrony mechanisms.

chrony_ensure_running() {
    systemctl enable --now chrony.service
}

chrony_validate() {
    if ! systemctl is-active --quiet chrony.service; then
        die "chrony.service is not active."
        return 1
    fi

    if chronyc tracking >/dev/null 2>&1; then
        return 0
    fi

    log_warn "chrony is running but synchronization is not yet confirmed."
    return 2
}
