set -euo pipefail

reload_services() {
  info "Reloading services to apply new configs..."

  # sshd
  systemctl reload ssh || systemctl restart ssh || true

  # journald
  systemctl restart systemd-journald || true

  # fail2ban
  systemctl restart fail2ban || true
}
