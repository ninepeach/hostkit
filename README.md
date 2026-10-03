# HostKit

Small, auditable Debian host setup tools.

**Status:** v0.1 implementation freeze — Debian 13 VM validation next  
**Supported platforms:** Debian 13; Alpine Linux ROUTER (early development)

HostKit prepares Linux hosts for a small number of explicit roles without turning host setup into a configuration-management framework.

Debian and Alpine are independent implementations. HostKit does not introduce a cross-distribution package, service, or networking abstraction merely to share code.

Its priorities are:

```text
Data Safety > Correctness > Simplicity > Maintainability > Performance > Features
```

The design deliberately favors a small core, explicit boundaries, inspect-before-mutate behavior, HostKit-owned drop-ins, effective-state verification, and fail-safe handling of ambiguous state.

## Platforms

```text
HostKit
├── debian/
│   ├── modules/
│   └── build/
└── alpine/
    ├── modules/
    └── build/
```

Debian 13 remains the primary v0.1 validation target.

The Alpine implementation is intentionally narrower: its first target is a small VM router appliance. Tailscale is deliberately outside HostKit ownership and is installed/configured manually. Debian code is not being converted into an Alpine compatibility layer.

Alpine ROUTER now contains independent mechanisms for DHCP uplink/LAN configuration, DHCPv4 validation, dnsmasq rendering, persistent nftables rules, and PPPoE peer rendering. Destructive live takeover remains disabled until the Alpine rollback path and VM end-to-end behavior are validated.

## Products

```text
HostKit
├── INIT
│   Prepare a Debian host
├── SECURITY
│   Secure host management
└── ROUTER
    Turn a Debian machine into a home router
```

### INIT

`debian13-init.sh` establishes a conservative Debian 13 baseline:

- essential administration packages
- network diagnostic tools
- chrony time synchronization
- unattended security updates
- login-session `nofile=65535`
- operational health checks

INIT does **not** change SSH, users, firewall, routing, forwarding, NAT, or network topology.

### SECURITY

SECURITY is designed to establish an administrative access chain:

```text
Host Firewall -> SSH -> Admin User -> sudo -> root
```

The reusable user, sudo, authorized-key, SSH, nftables, and confirmed-transaction mechanisms are implemented and tested at the module level.

The final `debian13-security.sh` entry point is intentionally **not released yet**. SSH/firewall changes can remove remote access, so release requires Debian 13 end-to-end validation of the complete 180-second rollback and new-authenticated-SSH-session confirmation path.

### ROUTER

`debian13-router.sh` targets a simple home router with one uplink and one LAN.

The v0.1 target includes:

- existing or DHCP uplink
- PPPoE uplink
- one LAN
- IPv4 forwarding
- NAT44 masquerade
- stateful nftables forwarding policy
- optional LAN DHCPv4 and DNS through dnsmasq
- native IPv6 when actually provided by the ISP
- DHCPv6 prefix delegation / RA where the real uplink supports it

ROUTER is not a general-purpose routing suite. Multi-WAN, dynamic routing, SD-WAN, VPN orchestration, and generic network management are outside v0.1.

The currently released build path is deliberately conservative: it preserves existing network ownership, requires one unambiguous IPv4 default-route uplink, enables IPv4 forwarding, and preserves the existing IPv6-forwarding state.

NAT44/firewall mechanisms and isolated Linux-network-namespace datapath tests exist, including packet-level masquerade verification and rejection of unsolicited WAN-to-LAN forwarding. Active ownership of LAN, DHCP/PPPoE, dnsmasq, persistent firewall state, and IPv6 PD/RA remains gated on Debian 13 end-to-end validation.

## Current Validation State

The implementation phase is substantially complete. The next milestone is validation on a disposable Debian 13 VM before expanding live ownership.

Already covered in the repository:

- module-level unit tests
- standalone build smoke tests
- strict router configuration validation
- DHCP subnet, gateway, network, and broadcast safety checks
- managed-file ownership and idempotency checks
- forwarding runtime/persistent mechanisms
- nftables syntax/application integration
- isolated router forwarding tests
- packet-level NAT44 observation with tcpdump
- unsolicited WAN-to-LAN negative testing
- systemd-backed confirmed rollback integration tests

Still requiring real Debian 13 end-to-end validation:

- INIT on a clean Debian 13 installation
- SECURITY SSH + firewall transaction and recovery
- successful new authenticated SSH session before SECURITY commit
- ROUTER DHCP uplink ownership
- ROUTER PPPoE uplink ownership
- LAN address and dnsmasq activation
- persistent nftables lifecycle and rollback
- restart/reboot convergence
- IPv6 prefix delegation and router advertisements on a real supporting uplink

Until those tests pass, HostKit should not be described as production-ready.

## Recommended Workflow

For a fresh server:

```text
INIT -> SECURITY
```

For a fresh router:

```text
INIT -> ROUTER
```

For a secured router:

```text
INIT -> SECURITY -> ROUTER
```

These are recommendations, not dependency chains.

INIT is the recommended baseline for a fresh Debian 13 host. SECURITY and ROUTER are designed to establish their own required prerequisites and do not require INIT to have run previously.

## Build from Source

Build a standalone artifact from the repository root:

```bash
./tools/build.sh init
./tools/build.sh router
./tools/build.sh alpine router
```

Generated artifacts:

```text
dist/debian13-init.sh
dist/debian13-router.sh
dist/alpine-router.sh
```

The generated scripts contain their required modules and do not depend on the HostKit source tree at runtime.

SECURITY will become a build target only after its complete remote-access transaction has passed Debian 13 end-to-end validation.

## Test

Run the local unit and build suite:

```bash
./tests/run.sh
```

Run an individual module test:

```bash
./tests/module.sh ssh
./tests/module.sh network
./tests/module.sh transaction
```

Run all module tests:

```bash
./tests/module.sh all
```

Debian 13 integration tests live under `tests/integration/`. Tests that require unavailable kernel capabilities or systemd as PID 1 must report **SKIP**, never a false PASS.

## Safety Model

HostKit follows several non-negotiable rules:

- inspect before mutating
- never overwrite an administrator-owned file merely because HostKit wants the same path
- prefer dedicated managed files and native drop-ins
- ambiguous or unknown state must not become a destructive guess
- verify effective runtime state rather than treating written configuration as proof
- preserve the old management path until its replacement is independently verified
- arm independent rollback before access-critical APPLY
- never kill a rollback that has already begun recovery
- do not introduce speculative kernel/network tuning

For dangerous operations the intended lifecycle is:

```text
INSPECT
  ↓
CLASSIFY
  ↓
PLAN
  ↓
STAGE
  ↓
STATIC VALIDATE
  ↓
ARM ROLLBACK
  ↓
APPLY
  ↓
RUNTIME / EXTERNAL VERIFY
  ├─ success -> COMMIT -> DISARM
  └─ failure / timeout -> ROLLBACK
```

The default confirmed-transaction rollback window is **180 seconds**.

## Automation Boundary

HostKit does not run a resident agent. Management remains ordinary SSH plus explicit HostKit CLI/script execution.

Commands and generated artifacts should remain automation-friendly: deterministic inputs, meaningful exit status, explicit logging, and no hidden interactive control plane. A future external agent may invoke these interfaces, but HostKit v0.x does not reserve an RPC, socket, plugin, or daemon API in advance.

## Architecture

```text
Platform Modules -> Platform Build Definitions -> Standalone Distribution Scripts
```

Modules provide small mechanisms. Build definitions own product policy and orchestration. Generated scripts are plain auditable shell. Distribution-specific implementations may duplicate code when that keeps their operating-system contracts explicit.

HostKit intentionally has no:

- configuration DSL
- runtime module loader
- plugin framework
- dependency resolver framework
- inventory or state database
- Web UI
- secret manager
- GitOps/application deployment layer
- Docker/Kubernetes orchestration
- Tailscale installation, authentication, or tailnet policy
- a resident HostKit agent or remote-control daemon

## Documentation

- [Design](docs/design.md) — architecture and engineering principles
- [Conventions](docs/conventions.md) — module, state, transaction, and shell conventions
- [INIT](docs/init.md) — base-host behavior and boundaries
- [SECURITY](docs/security.md) — access safety and transaction design
- [ROUTER](docs/router.md) — router scope, networking, DHCP/DNS, firewall, and IPv6 design

## v0.1 Release Gate

The source implementation is now at the point where additional speculative configuration would reduce confidence rather than improve it.

The next step is a clean Debian 13 VM validation pass. Failures found there should drive the remaining code changes.

v0.1 can be considered ready only after the required VM/E2E cases pass and the results are reproducible.

## License

License information will be added before the first release.
