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
# on the target Debian 12 host as root
curl -fsSL https://raw.githubusercontent.com/ninepeach/hostkit/scripts/deb12-init.sh | bash
