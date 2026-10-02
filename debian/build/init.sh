# HostKit INIT product definition.

MODULES=(
    core
    apt
    packages
    network-tools
    chrony
    unattended-upgrades
    system-health
)

hostkit_main() {
    require_root
    require_debian_13
    require_command apt-get dpkg-query grep getent ip systemctl chronyc df awk mktemp install cmp apt-config

    log_info "HostKit INIT: Debian 13 base-host initialization."

    network_require_connectivity

    local free_kb
    free_kb="$(health_root_free_kb)"
    if [ "$free_kb" -lt 262144 ]; then
        die "Insufficient free space on root filesystem (minimum 256 MiB)."
        return 1
    fi

    apt_update

    local -a packages missing
    packages=(
        "${HOSTKIT_INIT_BASE_PACKAGES[@]}"
        "${HOSTKIT_INIT_NETWORK_PACKAGES[@]}"
        chrony
        unattended-upgrades
    )

    mapfile -t missing < <(packages_missing "${packages[@]}")
    if [ "${#missing[@]}" -gt 0 ]; then
        apt_install "${missing[@]}"
    else
        log_ok "Required packages are already installed."
    fi

    chrony_ensure_running
    unattended_upgrades_enable

    local ntp_status="SYNCED"
    if chrony_validate; then
        log_ok "Time synchronization is available."
    else
        case "$?" in
            2) ntp_status="PENDING" ;;
            *) return 1 ;;
        esac
    fi

    if ! unattended_upgrades_validate; then
        die "Unattended security updates could not be validated."
        return 1
    fi
    log_ok "Unattended security updates are enabled."

    local failed_units
    failed_units="$(health_failed_units_count)"

    printf '\nHostKit Debian 13 Init\n\n'
    printf '%-14s %s\n' "OS" "Debian 13"
    printf '%-14s %s\n' "Network" "OK"
    printf '%-14s %s\n' "DNS" "OK"
    printf '%-14s %s\n' "NTP" "$ntp_status"
    printf '%-14s %s\n' "Auto Updates" "ENABLED"
    printf '%-14s %s\n' "Failed Units" "$failed_units"
    printf '%-14s %s\n' "Disk" "OK"
    printf '\n%-14s %s\n' "STATUS" "OK"
}
