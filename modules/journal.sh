#!/usr/bin/env bash
# ulimit + journald caps
set -euo pipefail

set_limits_and_journald() {
  local lf=/etc/security/limits.d/90-nofile.conf
  cat >"$lf" <<EOF
* soft nofile ${LIMIT_NOFILE}
* hard nofile ${LIMIT_NOFILE}
root soft nofile ${LIMIT_NOFILE}
root hard nofile ${LIMIT_NOFILE}
EOF

  local jf=/etc/systemd/journald.conf.d/limits.conf
  mkdir -p /etc/systemd/journald.conf.d
  cat >"$jf" <<EOF
[Journal]
SystemMaxUse=${JOURNALD_MAXUSE}
RuntimeMaxUse=${JOURNALD_MAXUSE}
Storage=auto
Compress=yes
Seal=yes
EOF
  systemctl restart systemd-journald || true
}
