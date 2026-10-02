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

Once published, each script can be downloaded and run independently on a Debian 13 host.

## What to Run

### Initialize a host

```text
debian13-init.sh
```

Use INIT on a fresh Debian 13 installation.

It prepares the base operating system, including packages, diagnostics, time synchronization, logging, and security updates.

INIT does not change SSH, users, firewall, or routing.

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

### Configure a router

```text
debian13-router.sh
```

Use ROUTER when the Debian host should operate as a network router or gateway.

It manages:

- network interfaces
- forwarding
- routing
- router firewall
- NAT
- DHCP/DNS where configured

ROUTER can be used whether or not SECURITY has already been applied.

## Typical Usage

Standard server:

```text
INIT -> SECURITY
```

Router without separate SECURITY setup:

```text
INIT -> ROUTER
```

Secured host that later becomes a router:

```text
INIT -> SECURITY -> ROUTER
```

Products are designed to compose without requiring every product to be installed.

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

Build instructions will be added when the first distribution script is implemented.

## Documentation

See [docs/design.md](docs/design.md) for architecture, product boundaries, transaction semantics, rollback behavior, firewall composition, and development principles.

## License

License information will be added before the first release.
