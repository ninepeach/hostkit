set -euo pipefail

assert_root(){ [[ $EUID -eq 0 ]] || die "Run as root"; }

check_debian12() {
  if ! grep -qi "debian" /etc/os-release; then
    warn "This script targets Debian. Continue at your own risk."
  fi
  if ! grep -qi "bookworm" /etc/os-release; then
    warn "Not Debian 12 (bookworm). Proceeding anyway."
  fi
}

preflight_guard() {
  # If SSH public key provided -> OK
  if [[ -n "${SSH_PUBKEY//[[:space:]]/}" ]]; then
    echo "[INFO] Preflight: SSH public key provided -> OK"
    return
  fi

  # No public key -> require both password auth enabled AND a non-empty user password
  if [[ "${ALLOW_PASSWORD_SSH}" != "true" || -z "${NEW_USER_PASSWORD}" ]]; then
    echo "[ERROR] Unsafe configuration detected!"
    echo "        - No SSH public key provided."
    echo "        - Root SSH login is disabled by design."
    echo "        - NEW_USER_PASSWORD is empty OR password login disabled."
    echo
    echo "This would lock you out of the server."
    echo
    echo "✅ Correct usage examples:"
    echo "  # Option 1: provide a public key (recommended)"
    echo "  SSH_PUBKEY='ssh-ed25519 AAAA... you@host' \\"
    echo "    bash deb12-init.sh"
    echo
    echo "  # Option 2: allow password login with a strong password"
    echo "  ALLOW_PASSWORD_SSH=true NEW_USER_PASSWORD='StrongPass#2025' \\"
    echo "    bash deb12-init.sh"
    echo
    exit 1
  fi

  echo "[INFO] Preflight: no public key, but password login enabled and NEW_USER_PASSWORD set -> OK"
}
