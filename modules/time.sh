set -euo pipefail

setup_timezone_ntp() {
  info "time: timezone=$TIMEZONE, enabling chrony"
  timedatectl set-timezone "$TIMEZONE" || true
  systemctl enable --now chrony || true
}
