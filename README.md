# HostKit

Small, auditable Linux host setup tools.

**Status:** Early development  
**Supported platform:** Debian 13

HostKit provides standalone scripts for initializing, securing, and configuring Linux hosts without requiring a configuration-management framework on the target machine.

## Quick Start

> HostKit is under active development. Distribution scripts are not published yet.

The planned standalone scripts are:

```text
debian13-init.sh
debian13-security.sh
debian13-router.sh
```

Each product is a standalone entry point. On a fresh Debian 13 host, running INIT first is the recommended baseline, but it is not a hard dependency for SECURITY or ROUTER.

## What to Run

### Initialize a host

```text
debian13-init.sh
```

Use INIT on a fresh Debian 13 installation.

It prepares the base operating system, including packages, diagnostics, time synchronization, logging, and security updates.

INIT does not change SSH, users, firewall, forwarding, or router policy.

### Secure a host

```text
debian13-security.sh
```

Use SECURITY to configure administrative access and host protection.

It manages:

- admin user
- sudo
- SSH
- authorized keys
- host firewall

SECURITY protects access-critical changes with rollback so a bad SSH or firewall configuration does not permanently lock you out.

### Configure a home router

```text
debian13-router.sh
```

ROUTER turns a Debian 13 physical machine into a simple home Internet router.

Its initial scope includes:

- preserving an already-working Internet uplink
- DHCP uplink
- PPPoE uplink
- one LAN
- IPv4 forwarding and NAT44 masquerade
- nftables firewall policy
- optional LAN DHCPv4 and local DNS
- native IPv6 forwarding when the ISP provides usable IPv6
- DHCPv6 prefix delegation and LAN router advertisements where available

ROUTER is not a general-purpose routing suite. Multi-WAN, dynamic routing, SD-WAN, VPN orchestration, and generic network management are outside v0.1.

Without a configuration file, ROUTER preserves current IP addresses, routes, DNS, and DHCP services, detects the active Internet uplink from the current default route, enables IPv4 forwarding, and enables NAT44 masquerade on that uplink. It refuses to guess when the active uplink cannot be determined safely.

A configuration file is used only when HostKit should take ownership of additional network state such as WAN DHCP/PPPoE, LAN addressing, or LAN DHCP/DNS.

## Typical Usage

Recommended fresh server workflow:

```text
INIT -> SECURITY
```

Recommended fresh router workflow:

```text
INIT -> ROUTER
```

Secured router:

```text
INIT -> SECURITY -> ROUTER
```

These are recommended workflows, not dependency chains. SECURITY and ROUTER can also be run directly on an already-maintained Debian 13 host. Each product checks and establishes only the prerequisites required for its own contract rather than invoking another complete HostKit product.

## Safety

SSH, firewall, and network changes can make a remote machine unreachable.

HostKit treats these as critical operations and uses transactional changes with automatic rollback where required.

When SECURITY changes remote SSH access, keeping the existing SSH session alive is not considered sufficient verification. A new authenticated connection is required before the change is committed.

## Build from Source

HostKit distribution scripts are built from small reusable shell modules.

The source layout is:

```text
debian/
├── modules/
└── build/

tools/
└── build.sh

dist/
├── debian13-init.sh
├── debian13-security.sh
└── debian13-router.sh
```

INIT can now be built from the repository root with:

```bash
./tools/build.sh init
```

The generated artifact is:

```text
dist/debian13-init.sh
```

SECURITY and ROUTER build definitions are not implemented yet.

## Documentation

- [Design](docs/design.md) — architecture, composition, safety invariants, and development principles
- [Conventions](docs/conventions.md) — CLI, exit status, logging, dry-run, idempotency, transactions, rollback, and generated-artifact rules
- [INIT](docs/init.md) — base-host initialization behavior and boundaries
- [SECURITY](docs/security.md) — administrative access, SSH, firewall, mutation ordering, transactions, and rollback
- [ROUTER](docs/router.md) — home-router scope, uplinks, LAN, IPv4 NAT, IPv6, DHCP/DNS, firewall, and network safety

## License

License information will be added before the first release.
