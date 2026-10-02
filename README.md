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
debian13-gateway.sh
```

Each product is a standalone entry point. On a fresh Debian 13 host, running INIT first is the recommended baseline, but it is not a hard dependency for SECURITY or GATEWAY.

## What to Run

### Initialize a host

```text
debian13-init.sh
```

Use INIT on a fresh Debian 13 installation.

It prepares the base operating system, including packages, diagnostics, time synchronization, logging, and security updates.

INIT does not change SSH, users, firewall, forwarding, or gateway policy.

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

### Configure a gateway

```text
debian13-gateway.sh
```

Use GATEWAY when the Debian host should provide an upstream/downstream network gateway role.

Initial capabilities include:

- uplink configuration using DHCP, static addressing, or PPPoE
- LAN addressing
- IP forwarding
- NAT/masquerade
- local DNS service
- optional DHCP server
- gateway firewall policy

GATEWAY is intentionally smaller than a general-purpose router. It is not a dynamic-routing suite or generic network-management system.

By default, the gateway role enables forwarding, NAT, and local DNS. DHCP server service is enabled only when a DHCP range is explicitly configured. Local DNS can be explicitly disabled.

## Typical Usage

Recommended fresh server workflow:

```text
INIT -> SECURITY
```

Recommended fresh gateway workflow:

```text
INIT -> GATEWAY
```

Secured gateway:

```text
INIT -> SECURITY -> GATEWAY
```

These are recommended workflows, not dependency chains. SECURITY and GATEWAY can also be run directly on an already-maintained Debian 13 host. Each product checks and establishes only the prerequisites required for its own contract rather than invoking another complete HostKit product.

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
└── debian13-gateway.sh
```

Build instructions will be added when the first distribution script is implemented.

## Documentation

- [Design](docs/design.md) — architecture, composition, safety invariants, and development principles
- [Conventions](docs/conventions.md) — CLI, exit status, logging, dry-run, idempotency, transactions, rollback, and generated-artifact rules
- [INIT](docs/init.md) — base-host initialization behavior and boundaries
- [SECURITY](docs/security.md) — administrative access, SSH, firewall, mutation ordering, transactions, and rollback
- [GATEWAY](docs/gateway.md) — uplink, LAN, forwarding, NAT, DNS, optional DHCP, and gateway safety

## License

License information will be added before the first release.
