# OpenSSH server mechanisms.

ssh_validate_port() {
    local value="$1"
    case "$value" in ''|*[!0-9]*) return 1 ;; esac
    [ "$value" -ge 1 ] && [ "$value" -le 65535 ]
}

ssh_validate_config() {
    sshd -t -f "$1"
}

ssh_effective_port() {
    sshd -T 2>/dev/null | awk '$1 == "port" {print $2; exit}'
}

ssh_reload() {
    systemctl reload ssh.service
}

ssh_is_active() {
    systemctl is-active --quiet ssh.service
}
