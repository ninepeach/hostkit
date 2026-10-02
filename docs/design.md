# HostKit

HostKit is a small, auditable toolkit for turning a fresh Linux host into a clean, secure, and role-ready system.

The current implementation target is **Debian 13**.

HostKit deliberately favors a small core, explicit boundaries, and composition over framework features.

## Priorities

In order:

1. Data Safety
2. Correctness
3. Simplicity
4. Maintainability
5. Performance
6. Features

When these priorities conflict, the earlier item wins.

## Scope

HostKit configures the host operating system itself.

The initial products are:

- **INIT** — establish a clean, maintainable, diagnosable base host.
- **SECURITY** — establish secure administrative access and host protection.
- **ROUTER** — configure the host as a network router/gateway.

HostKit is not intended to become a general-purpose configuration-management framework.

## Non-Goals

HostKit does not aim to provide:

- a configuration DSL
- a plugin framework
- dependency resolution
- inventory or fleet management
- a state database
- a web UI
- secret management
- GitOps or application deployment
- container or Kubernetes deployment
- distribution abstraction before a second distribution actually requires it

## Architecture

HostKit has three layers:

```text
Modules -> Build Definitions -> Distribution Scripts
```

### Modules

A module implements a reusable mechanism.

Examples:

```text
apt
packages
chrony
user
sudo
ssh
nftables
network
forwarding
dnsmasq
nat
transaction
```

A module:

- exports functions
- performs no host modification merely by being sourced
- does not know which final product uses it
- is idempotent where reasonably possible
- keeps policy out of reusable mechanisms

### Build Definitions

A build definition composes modules and owns product policy and workflow.

The initial build definitions are:

```text
init
security
router
```

A build definition is intentionally simple. HostKit should not invent a DSL to describe module composition.

### Distribution Scripts

Build output is a standalone script suitable for execution on the target host.

The target host must not require:

- the HostKit source tree
- a Git checkout
- a runtime module loader
- additional HostKit downloads

Initial artifacts:

```text
debian13-init.sh
debian13-security.sh
debian13-router.sh
```

## Product Model

Products are composable but should not have unnecessary hard dependencies.

Valid paths include:

```text
INIT -> SECURITY
INIT -> ROUTER
INIT -> SECURITY -> ROUTER
```

ROUTER may use an existing SECURITY configuration, but SECURITY is not a prerequisite for ROUTER.

Shared behavior is reused through modules, not by forcing one product script to execute another product script.

## INIT

INIT transforms a fresh Debian 13 installation into a clean, maintainable, and diagnosable base host.

Responsibilities include:

- preflight validation
- APT maintenance
- essential base tools
- network diagnostic tools
- locale
- optional hostname configuration
- optional timezone configuration
- time synchronization
- logging baseline
- unattended security updates
- conservative cleanup
- final validation

INIT does not configure:

- administrative users
- sudo policy
- SSH policy
- authorized keys
- firewall policy
- routing
- NAT
- DHCP/DNS service
- containers or Kubernetes
- generic performance tuning

## SECURITY

SECURITY owns administrative access and host security policy.

Responsibilities include:

- administrative user configuration
- sudo configuration
- SSH configuration
- authorized keys
- host firewall policy
- safe transactional application of access-critical changes

The management access chain is treated as one safety domain:

```text
Firewall -> SSH -> Admin User -> sudo -> root privilege
```

### SSH Recovery Invariant

HostKit host firewall policy keeps TCP port 22 allowed as a conservative recovery path.

If SSH is configured to use another port, both TCP 22 and the configured SSH port may be allowed by the firewall.

An allowed firewall port does not imply that sshd must listen on that port.

HostKit prioritizes recoverability over cosmetic firewall minimalism.

## ROUTER

ROUTER configures the host as a network router/gateway.

Responsibilities include:

- network interface configuration
- forwarding
- router firewall policy
- routing
- NAT
- DHCP/DNS where configured
- validation of the resulting network role

ROUTER can operate in two situations:

1. SECURITY already exists.
2. SECURITY has never been applied.

When SECURITY exists, ROUTER must preserve its host-management policy.

When SECURITY does not exist, ROUTER must establish the minimum host policy required to operate safely.

ROUTER owns router-specific policy; it must not blindly overwrite unrelated host-security policy.

Likewise, applying SECURITY later must not destroy ROUTER policy.

## Firewall Composition

Host firewall policy and router policy are separate responsibilities even though both use nftables.

Conceptually:

```text
Host policy
    Security-managed when SECURITY is present
    Minimum safe baseline when ROUTER operates alone

Router policy
    Router-managed forwarding, NAT, and router-specific rules
```

The nftables module provides mechanisms such as backup, validation, application, and restoration. It does not own final firewall policy.

The exact Debian 13 ruleset layout is an implementation detail and should remain as simple as possible.

## Critical Changes and Transactions

A syntactically valid configuration can still make a remote host unreachable.

Access-critical and network-critical changes therefore require transactional protection.

The transaction lifecycle is:

```text
BACKUP
  |
STAGE
  |
STATIC VALIDATE
  |
ARM ROLLBACK
  |
APPLY
  |
RUNTIME / EXTERNAL VALIDATE
  |
COMMIT
  |
DISARM ROLLBACK
```

Rollback must not depend on the SSH session that initiated the change remaining alive.

On Debian 13, the implementation should use a system-managed rollback mechanism rather than relying solely on a background shell sleep process.

The default rollback window is expected to be approximately **180 seconds**. The exact interface remains an implementation decision.

### Transaction Responsibility

The generic transaction mechanism owns:

- backup registration
- rollback arming
- commit
- rollback
- restoration of relevant configuration and runtime state

It does **not** decide whether a product is healthy.

Verification belongs to the product:

```text
transaction
    mechanism

security
    SSH/access verification

router
    routing/connectivity verification
```

This keeps transaction mechanics reusable without inventing a generic health framework.

## SECURITY External Verification

Keeping an existing SSH session alive is not proof that new SSH connections work.

For a remote SECURITY transaction, successful verification should require a **new authenticated SSH session created after the change**.

When changing the SSH port, the new session must use the newly configured server-side SSH port.

For example:

```text
configured SSH port: 10220

new authenticated session on 10220 -> valid verification
new session on old port 22              -> not verification of 10220
existing SSH session remains alive      -> not verification
```

Server-side port is the primary verification signal.

User identity, connection creation time, and original client address may be used as additional safeguards where appropriate.

The exact Debian 13 mechanism for reliably detecting a newly authenticated OpenSSH session must be validated before implementation.

For local console execution, external SSH verification may not be applicable; an explicit confirmation path can be used instead.

## Rollback Semantics

Rollback means restoring the relevant pre-transaction state, not merely restoring one configuration file.

A transaction may need to preserve:

- files that existed before the transaction
- absence of files created by the transaction
- service runtime state
- service enabled/disabled state
- active firewall state

Every critical modification must therefore be registered with the transaction deliberately.

Partial rollback must not be presented as full rollback.

## Idempotency

Re-running a HostKit product should converge on the same intended state.

It must not unnecessarily:

- duplicate configuration
- duplicate firewall rules
- duplicate users
- duplicate repositories
- append repeated configuration fragments

Where practical, HostKit should prefer dedicated managed files or drop-ins over rewriting unrelated user configuration.

## Network Safety

Network configuration can destroy the management path even when its syntax is valid.

HostKit must therefore:

- detect the existing network-management environment
- avoid blindly disabling competing network managers
- refuse ambiguous destructive migrations or require explicit intent
- protect critical changes with rollback
- validate the resulting runtime state

ROUTER verification is product-specific and must not be forced into SECURITY's SSH verification model.

## Debian 13

Debian 13 is the only supported platform for the initial implementation.

Current implementation choices include:

- systemd
- APT
- OpenSSH
- nftables
- chrony
- modern iproute2 tooling

Additional implementation choices should be made only when required by an actual HostKit product.

HostKit should not introduce cross-distribution abstractions until another supported distribution creates a real need.

## Repository Layout

The initial repository should remain small:

```text
HostKit/
├── README.md
├── LICENSE
├── debian/
│   ├── modules/
│   └── build/
├── tools/
│   └── build.sh
└── dist/
```

The high-level architecture and safety contracts are maintained in this document.

## Design Rule

When choosing between a clever abstraction and an explicit small implementation, prefer the explicit small implementation unless real duplication or correctness requirements prove otherwise.

HostKit should grow from demonstrated needs, not anticipated framework requirements.
