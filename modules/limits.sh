#!/usr/bin/env bash
set -euo pipefail

set_limits() {
  local lf=/etc/security/limits.d/90-nofile.conf
  cat >"$lf" <<EOF
* soft nofile ${LIMIT_NOFILE}
* hard nofile ${LIMIT_NOFILE}
root soft nofile ${LIMIT_NOFILE}
root hard nofile ${LIMIT_NOFILE}
EOF
}
