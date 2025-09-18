set -euo pipefail

check_debian12() {
  if ! grep -qi "debian" /etc/os-release; then
    warn "This script targets Debian. Continue at your own risk."
  fi
  if ! grep -qi "bookworm" /etc/os-release; then
    warn "Not Debian 12 (bookworm). Proceeding anyway."
  fi
}
