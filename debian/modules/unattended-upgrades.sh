# Unattended security-update mechanisms.

unattended_upgrades_enable() {
    local path="${HOSTKIT_UNATTENDED_PATH:-/etc/apt/apt.conf.d/52hostkit-unattended-upgrades}"
    local tmp
    tmp="$(mktemp)"

    cat >"$tmp" <<'EOF'
# Managed by HostKit. Do not edit manually.
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    if [ -e "$path" ]; then
        local first=
        IFS= read -r first <"$path" || true
        if [ "$first" != "# Managed by HostKit. Do not edit manually." ]; then
            rm -f "$tmp"
            die "Refusing to overwrite unattended-upgrades file not owned by HostKit: $path"
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

unattended_upgrades_validate() {
    local path="${HOSTKIT_UNATTENDED_PATH:-/etc/apt/apt.conf.d/52hostkit-unattended-upgrades}"
    test -r "$path" &&
        apt-config dump 2>/dev/null | grep -q 'APT::Periodic::Unattended-Upgrade "1";' &&
        apt-config dump 2>/dev/null | grep -q 'Unattended-Upgrade::Automatic-Reboot "false";'
}
