#!/usr/bin/env bash
# SSH daemon hardening
set -euo pipefail

setup_sshd_security() {
  local cfg="/etc/ssh/sshd_config"
  [[ -f ${cfg}.orig ]] || cp -a "$cfg" "${cfg}.orig"

  # map true/false -> yes/no
  local pass_auth="no"
  [[ "${ALLOW_PASSWORD_SSH}" == "true" ]] && pass_auth="yes"

  sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin no/' "$cfg"
  sed -ri "s/^#?PasswordAuthentication.*/PasswordAuthentication ${pass_auth}/" "$cfg"
  sed -ri 's/^#?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$cfg"
  sed -ri 's/^#?UsePAM.*/UsePAM yes/' "$cfg"
  sed -ri 's/^#?X11Forwarding.*/X11Forwarding no/' "$cfg"
  sed -ri 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$cfg"

  if grep -q '^#\?PubkeyAuthentication' "$cfg"; then
    sed -ri 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$cfg"
  else
    echo "PubkeyAuthentication yes" >>"$cfg"
  fi

  if ! grep -q "^AllowUsers" "$cfg"; then
    echo "AllowUsers ${NEW_USER}" >>"$cfg"
  else
    sed -ri "s/^AllowUsers.*/AllowUsers ${NEW_USER}/" "$cfg"
  fi

  if ! grep -q "^Port ${SSH_PORT}\b" "$cfg"; then
    if grep -q "^Port " "$cfg"; then
      sed -ri "s/^Port .*/Port ${SSH_PORT}/" "$cfg"
    else
      echo "Port ${SSH_PORT}" >>"$cfg"
    fi
  fi
}

reload_sshd() {
  systemctl reload ssh || systemctl restart ssh
}
