#!/usr/bin/env bash
# Fail2Ban baseline
set -euo pipefail

setup_fail2ban() {
  systemctl enable --now rsyslog || true
  systemctl enable --now fail2ban || true

  # neutralize any legacy jail.local (if present), but don't delete it
  if [[ -f /etc/fail2ban/jail.local ]]; then
    sed -ri 's/^(backend|logpath|enabled|port)[[:space:]]*=/# \0/' /etc/fail2ban/jail.local || true
  fi

  mkdir -p /etc/fail2ban/jail.d
  cat >/etc/fail2ban/jail.d/00-defaults.conf <<'EOF'
[DEFAULT]
ignoreip  = 127.0.0.1/8 ::1 10.0.0.0/16
findtime  = 10m
maxretry  = 5
bantime   = 1h
EOF

  cat >/etc/fail2ban/jail.d/sshd.conf <<EOF
[sshd]
enabled  = true
backend  = auto
logpath  = /var/log/auth.log
port     = ${SSH_PORT}
EOF

  if [[ "${ENVIRONMENT:-prod}" != "prod" ]]; then
    sed -ri 's/^bantime[[:space:]]*=.*/bantime = 10m/' /etc/fail2ban/jail.d/00-defaults.conf
  fi

  systemctl restart fail2ban || true
}