#!/usr/bin/env bash
set -euo pipefail

set_journald() {

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
