#!/usr/bin/env bash
# Debian 12 one-shot init hardening (iptables-only, modular)
set -euo pipefail

##### === Configurable variables === #####
NEW_USER="${NEW_USER:-devops}"
NEW_USER_PASSWORD="${NEW_USER_PASSWORD:-}"
NEW_USER_SUDO_NOPASSWD="${NEW_USER_SUDO_NOPASSWD:-true}"

SSH_PORT="${SSH_PORT:-22}"
SSH_PUBKEY="${SSH_PUBKEY:-}"
ALLOW_PASSWORD_SSH="${ALLOW_PASSWORD_SSH:-false}"   # "true"/"false" -> mapped to yes/no

ALLOW_HTTP="${ALLOW_HTTP:-true}"
ALLOW_HTTPS="${ALLOW_HTTPS:-true}"
EXTRA_TCP_PORTS="${EXTRA_TCP_PORTS:-}"              # e.g. "5432,9100"

TIMEZONE="${TIMEZONE:-UTC}"
LIMIT_NOFILE="${LIMIT_NOFILE:-1048576}"
JOURNALD_MAXUSE="${JOURNALD_MAXUSE:-200M}"
ENVIRONMENT="${ENV:-prod}"

SUDO_SECURE_PATH="${SUDO_SECURE_PATH:-/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin}"
SUDO_LOGFILE="${SUDO_LOGFILE:-/var/log/sudo.log}"
SUDO_TIMESTAMP_TIMEOUT="${SUDO_TIMESTAMP_TIMEOUT:-15}"
##########################################

# locate repo root and modules
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# === modules ===
# shellcheck source=../modules/*.sh
. "$BASE_DIR/modules/log.sh"
. "$BASE_DIR/modules/detect.sh"
. "$BASE_DIR/modules/apt.sh"
. "$BASE_DIR/modules/time.sh"
. "$BASE_DIR/modules/user_sudo.sh"
. "$BASE_DIR/modules/sshd.sh"
. "$BASE_DIR/modules/unattended.sh"
. "$BASE_DIR/modules/fail2ban.sh"
. "$BASE_DIR/modules/sysctl.sh"
. "$BASE_DIR/modules/limits.sh"
. "$BASE_DIR/modules/journal.sh"
. "$BASE_DIR/modules/firewall_iptables.sh"
. "$BASE_DIR/modules/services.sh"
. "$BASE_DIR/modules/summary.sh"


main() {
  assert_root
  check_debian12
  preflight_guard

  install_base_packages
  setup_timezone_ntp
  create_user
  ensure_sudo_ready
  setup_sshd_security
  setup_unattended_upgrades   # keep or comment out per host role
  setup_fail2ban
  sysctl_network_tuning
  set_limits
  set_journald
  firewall_iptables_apply
  reload_services
  print_summary
}

main "$@"
