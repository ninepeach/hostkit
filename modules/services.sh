set -euo pipefail

reload_services() {
  info "services: reloading sshd"
  systemctl reload ssh || systemctl restart ssh
}
