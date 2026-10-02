# Unattended security-update mechanisms.

unattended_upgrades_enable() {
    local path="/etc/apt/apt.conf.d/52hostkit-unattended-upgrades"
    local tmp
    tmp="$(mktemp)"

    cat >"$tmp" <<'EOF'
# Managed by HostKit. Do not edit manually.
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi

    install -m 0644 "$tmp" "$path"
    rm -f "$tmp"
}

unattended_upgrades_validate() {
    test -r /etc/apt/apt.conf.d/52hostkit-unattended-upgrades &&
        apt-config dump 2>/dev/null | grep -q 'APT::Periodic::Unattended-Upgrade "1";'
}
