set -euo pipefail

print_summary() {
  echo "=============================================="
  echo "Init complete."
  echo "User:           ${NEW_USER}"
  echo "SSH Port:       ${SSH_PORT}"
  echo "Root SSH:       disabled"
  echo "PasswordAuth:   ${ALLOW_PASSWORD_SSH}"
  echo "Firewall:       iptables"
  echo "HTTP/HTTPS:     ${ALLOW_HTTP}/${ALLOW_HTTPS}"
  echo "Extra Ports:    ${EXTRA_TCP_PORTS:-<none>}"
  echo "Timezone:       ${TIMEZONE}"
  echo "nofile limit:   ${LIMIT_NOFILE}"
  echo "journald cap:   ${JOURNALD_MAXUSE}"
  [[ -n "${SUDO_LOGFILE}" ]] && echo "sudo logfile:  ${SUDO_LOGFILE}"
  echo "sudo timeout:   ${SUDO_TIMESTAMP_TIMEOUT} min"

  # Show installed SSH key count
  local sshdir="/home/${NEW_USER}/.ssh"
  local authfile="${sshdir}/authorized_keys"
  if [[ -f "$authfile" ]]; then
    local key_count
    key_count=$(grep -cve '^[[:space:]]*$' "$authfile" || true)
    echo "SSH keys:       ${key_count}"
  else
    echo "SSH keys:       <none>"
  fi

  echo "=============================================="
  echo "Tip: verify you can log in via the new SSH port before closing your current session."
}