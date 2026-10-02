# INIT

INIT establishes a clean, maintainable, and diagnosable Debian 13 base host.

It is intentionally conservative. INIT does not turn a host into a secured server or router and does not change remote-access policy.

## Goals

After a successful INIT run, the host should have:

- a healthy Debian package-management baseline
- essential administration tools
- useful network diagnostics
- working time synchronization
- a sane logging baseline
- unattended security updates
- a clear final health summary

INIT follows one rule above all:

> Preserve sane Debian defaults. Configure only what HostKit has a concrete reason to change.

## Preconditions

INIT must verify before making material changes:

- effective UID is root
- operating system is Debian
- supported release is Debian 13
- required system facilities are present
- APT is usable
- sufficient disk space exists for the requested work
- network and DNS are available before operations that require them

A failed preflight must stop before partial configuration whenever possible.

Unsupported operating systems must fail explicitly rather than attempting best-effort execution.

## Base Packages

Initial base packages:

- ca-certificates
- curl
- vim
- git
- jq
- rsync
- unzip
- less

INIT should not install software merely because it is traditionally present on servers.

The following are intentionally not baseline requirements:

- wget
- nano
- htop
- tmux
- screen
- tree
- build-essential
- gcc
- make
- net-tools
- traceroute
- socat
- whois
- pciutils
- usbutils

A package can be added later when a HostKit responsibility demonstrates a real need for it.

## Network Diagnostics

Initial diagnostic tooling:

- iproute2
- iputils-ping
- dnsutils
- mtr-tiny
- tcpdump
- ethtool
- netcat-openbsd
- iperf3
- lsof

HostKit documentation and diagnostics use modern interfaces such as:

```text
ip addr
ip route
ip neigh
ss
```

Legacy net-tools commands are not part of the baseline.

## Locale

INIT may ensure that the system has a usable locale configuration.

It must not silently replace an already valid administrator-selected locale merely to impose a HostKit preference.

Any requested locale change must be explicit and validated.

## Hostname

Hostname changes are optional.

Without an explicit hostname request, INIT preserves the existing hostname.

A requested hostname must be validated before it is applied.

## Timezone

Timezone changes are optional.

Without an explicit timezone request, INIT preserves the existing timezone.

A requested timezone must be validated before it is applied.

## Time Synchronization

HostKit uses chrony for time synchronization on Debian 13.

INIT should:

- install chrony when required
- enable/start the appropriate service
- retain sane upstream defaults unless custom servers are explicitly requested
- validate runtime synchronization state

Useful validation includes:

```text
chronyc tracking
chronyc sources
```

Failure to become synchronized immediately is not necessarily an installation failure. INIT must distinguish configuration failure from a source that has not synchronized yet.

## Logging

INIT must not rewrite journald or logrotate configuration simply to claim ownership of logging.

If Debian 13 defaults satisfy HostKit requirements, they should be preserved.

HostKit should modify logging only for a documented operational requirement.

## Security Updates

INIT enables unattended security updates when the Debian 13 implementation can do so predictably.

Automatic reboot is disabled by default.

HostKit must never unexpectedly reboot a host as part of INIT.

## Cleanup

Cleanup must be conservative.

INIT must not remove packages merely because APT currently considers them automatically installed unless HostKit can establish that removal is safe.

Destructive cleanup is not a goal.

## Idempotency

A second INIT run must be safe.

It should converge rather than append or duplicate configuration.

Already-correct state should normally result in no material change.

## Failure Semantics

INIT distinguishes:

- **ERROR** — required state could not be established; run fails.
- **WARN** — host remains usable but a non-critical validation did not reach the preferred state.
- **OK** — required state is established.

Failures must identify the operation that failed and return a non-zero exit status.

INIT must not print a successful final status after a critical failure.

## Final Validation

The final report should be concise and operationally useful.

Conceptually:

```text
HostKit Debian 13 Init

OS            Debian 13
Network       OK
DNS           OK
NTP           SYNCED
Auto Updates  ENABLED
Failed Units  0
Disk          OK

STATUS        OK
```

Exact formatting is an implementation detail.

The summary must reflect observed state rather than merely report that commands were executed.

## Explicit Non-Responsibilities

INIT does not configure:

- administrative users
- sudo policy
- SSH policy
- authorized_keys
- firewall policy
- network topology
- IP forwarding policy (INIT preserves the existing kernel forwarding state)
- routing
- NAT
- DHCP/DNS server roles
- Tailscale or VPN products
- Docker
- Kubernetes
- generic sysctl tuning
- BBR or performance tuning

INIT is the recommended baseline for a fresh Debian 13 host, but SECURITY and GATEWAY do not require INIT to have been run previously. Those concerns belong to other products or remain outside HostKit.
