# HostKit INIT product definition.

MODULES=(
    core
    apt
    packages
    limits
    locale
    hostname
    timezone
    network-tools
    chrony
    unattended-upgrades
    system-health
)

hostkit_main() {
    require_root
    require_debian_13
    require_command apt-get dpkg-query grep getent ip systemctl df awk mktemp install cmp apt-config

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

    missing=()
    while IFS= read -r package; do
        [ -n "$package" ] && missing+=("$package")
    done < <(packages_missing "${packages[@]}")

    if [ "${#missing[@]}" -gt 0 ]; then
        apt_install "${missing[@]}"
    else
        log_ok "Required packages are already installed."
    fi

    require_command chronyc

    limits_configure_nofile 65535
    if ! limits_validate_nofile 65535; then
        die "Login-session nofile baseline could not be validated."
        return 1
    fi
    log_ok "Login-session nofile baseline is 65535."

    chrony_ensure_running
    unattended_upgrades_enable

    local ntp_status="SYNCED"
    local chrony_rc=0
    chrony_validate || chrony_rc=$?
    case "$chrony_rc" in
        0) log_ok "Time synchronization is available." ;;
        2) ntp_status="PENDING" ;;
        *) return 1 ;;
    esac

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
    printf '%-14s %s\n' "nofile" "65535"
    printf '%-14s %s\n' "Auto Updates" "ENABLED"
    printf '%-14s %s\n' "Failed Units" "$failed_units"
    printf '%-14s %s\n' "Disk" "OK"
    printf '\n%-14s %s\n' "STATUS" "OK"
}
