#!/usr/bin/env bash
# Fail2Ban baseline
set -euo pipefail

setup_fail2ban() {
  systemctl enable --now fail2ban || true
  local jail="/etc/fail2ban/jail.local"
  if [[ ! -f "$jail" ]]; then
    cat >"$jail" <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ${SSH_PORT}
logpath = %(sshd_log)s
backend = systemd
EOF
    [[ "$ENVIRONMENT" != "prod" ]] && sed -ri 's/^bantime = .*/bantime = 10m/' "$jail"
  fi
  systemctl restart fail2ban || true
}
