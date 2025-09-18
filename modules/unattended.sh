#!/usr/bin/env bash
# Unattended upgrades (security)
set -euo pipefail

setup_unattended_upgrades() {
  dpkg-reconfigure -fnoninteractive unattended-upgrades || true
  cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
  systemctl enable --now unattended-upgrades || true
}
