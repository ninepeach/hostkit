set -euo pipefail

create_user() {
  if ! id "$NEW_USER" &>/dev/null; then
    info "user: creating $NEW_USER"
    adduser --disabled-password --gecos "" "$NEW_USER"
  fi
  usermod -aG sudo "$NEW_USER"

  if [[ -n "${NEW_USER_PASSWORD}" ]]; then
    echo "${NEW_USER}:${NEW_USER_PASSWORD}" | chpasswd
  fi

  local sshdir="/home/${NEW_USER}/.ssh"
  mkdir -p "$sshdir"; chmod 700 "$sshdir"
  if [[ -n "${SSH_PUBKEY}" ]]; then
      echo "$SSH_PUBKEY" >"${sshdir}/authorized_keys"
      chmod 600 "${sshdir}/authorized_keys"
      chown -R "${NEW_USER}:${NEW_USER}" "$sshdir"
      info "SSH: public key installed for ${NEW_USER}"
  else
      info "SSH: no public key provided, skipping authorized_keys"
  fi
}

ensure_sudo_ready() {
  info "sudo: configuring sudoers drop-ins"
  if ! grep -qE '^[[:space:]]*#includedir[[:space:]]+/etc/sudoers.d' /etc/sudoers; then
    echo '#includedir /etc/sudoers.d' >> /etc/sudoers
  fi

  mkdir -p /etc/sudoers.d
  chmod 750 /etc/sudoers.d

  local d1="/etc/sudoers.d/00-defaults"
  {
    echo "Defaults secure_path=\"$SUDO_SECURE_PATH\""
    echo "Defaults env_reset"
    echo "Defaults umask=022"
    echo "Defaults timestamp_timeout=${SUDO_TIMESTAMP_TIMEOUT}"
    if [[ -n "${SUDO_LOGFILE}" ]]; then
      echo "Defaults logfile=\"$SUDO_LOGFILE\""
      touch "$SUDO_LOGFILE"; chmod 0600 "$SUDO_LOGFILE"; chown root:root "$SUDO_LOGFILE"
    fi
  } > "$d1"
  chmod 0440 "$d1"

  echo "%sudo ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-sudo-group
  chmod 0440 /etc/sudoers.d/10-sudo-group

  local d3="/etc/sudoers.d/90-${NEW_USER}"
  if [[ "${NEW_USER_SUDO_NOPASSWD}" == "true" ]]; then
    echo "${NEW_USER} ALL=(ALL) NOPASSWD:ALL" > "$d3"
  else
    echo "${NEW_USER} ALL=(ALL) ALL" > "$d3"
  fi
  chmod 0440 "$d3"

  visudo -c >/dev/null
}
