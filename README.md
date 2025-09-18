# Hostkit

Opinionated bootstrap & hardening scripts for Debian 12 servers.

## Features
- Non-root sudo user creation
- SSH hardening (no root login, key-only by default)
- iptables firewall (IPv4 + IPv6) with persistence
- Base packages (git, strace, vim, curl, htop, etc.)
- Optional unattended security upgrades (security-first)
- Sysctl network tuning (BBR, sane defaults)
- journald + ulimit sane defaults

## Quick start
```bash
# On a fresh Debian 12 host, run as root

# Option 1: with one public key
export NEW_USER=devops SSH_PUBKEY="ssh-ed25519 AAAA... dev@box" SSH_PORT=2222
curl -fsSL https://raw.githubusercontent.com/ninepeach/hostkit/main/dist/hostkit-deb12-init.sh | bash

# Option 2: with multiple public keys (newline separated, safest)
export NEW_USER=devops SSH_PORT=2222
export SSH_PUBKEY=$'ssh-ed25519 AAAA... user1@laptop\nssh-rsa BBBB... user2@desktop'
curl -fsSL https://raw.githubusercontent.com/ninepeach/hostkit/main/dist/hostkit-deb12-init.sh | bash

# Option 3: allow password login (not recommended, but possible)
export NEW_USER=devops ALLOW_PASSWORD_SSH=true NEW_USER_PASSWORD='StrongPass#2025' SSH_PORT=2222
curl -fsSL https://raw.githubusercontent.com/ninepeach/hostkit/main/dist/hostkit-deb12-init.sh | bash