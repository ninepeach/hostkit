# ROUTER

ROUTER configures a Debian 13 host to operate as a network router or gateway.

It is a complete router configuration product, but it does not require SECURITY to have been run first.

Valid compositions include:

```text
INIT -> ROUTER

INIT -> SECURITY -> ROUTER
```

SECURITY may also be applied later, provided each product preserves the other's owned policy.

## Responsibilities

ROUTER may manage:

- network interfaces
- WAN/LAN addressing
- routes
- IP forwarding
- router firewall policy
- forwarding policy
- NAT/masquerade
- DHCP
- local DNS service
- router-specific runtime validation

Initial Debian 13 implementation choices are expected to use:

- systemd-networkd
- nftables
- dnsmasq

These are implementation choices, not cross-platform abstractions.

## Independence from SECURITY

ROUTER must work when SECURITY is absent.

If SECURITY already exists, ROUTER preserves its host-management policy.

If SECURITY is absent, ROUTER establishes the minimum host policy necessary to operate safely, including a recoverable management path.

This means:

> ROUTER can use SECURITY state, but does not require SECURITY as a product dependency.

Shared mechanisms are reused through modules rather than by invoking SECURITY as a prerequisite.

## Firewall Responsibilities

ROUTER owns router-specific policy, including:

- FORWARD behavior
- NAT
- router-specific INPUT requirements such as DHCP/DNS on trusted interfaces

SECURITY owns host-management policy when present.

The implementation must compose these policies predictably and must not rely on execution order to avoid accidental rule loss.

The exact nftables file/chain layout should remain simple and is an implementation decision until validated on Debian 13.

## Network Manager Safety

ROUTER must detect the existing network-management environment before taking ownership of interfaces.

It must not blindly disable or mask NetworkManager, ifupdown, systemd-networkd, or another manager simply because HostKit prefers one implementation.

When existing ownership conflicts with the requested router configuration, ROUTER must either:

- perform an explicitly requested migration with rollback, or
- refuse and explain the conflict

Ambiguous destructive migration is not acceptable.

## Network Changes Are Critical

A syntactically valid network configuration can still make a remote machine unreachable.

Changes to management addresses, routes, interface ownership, forwarding, or firewall policy therefore require transactional protection when they can affect reachability.

The generic transaction mechanism can be shared with SECURITY, but ROUTER owns its own success criteria.

## Transaction Model

ROUTER uses the common transaction lifecycle:

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
ROUTER-SPECIFIC VALIDATE
  |
COMMIT
  |
DISARM ROLLBACK
```

Rollback must restore the relevant previous network and firewall state and must not depend on the initiating SSH session surviving.

## Verification

ROUTER must not blindly reuse SECURITY's SSH verification rule.

Examples:

- changing a LAN management address may require validation through the new address
- changing WAN configuration may require upstream connectivity validation
- enabling forwarding requires forwarding-path validation
- DHCP/DNS roles require service and interface validation

A successful ping alone is not a universal proof that a router configuration is correct.

Each router operation must define what evidence is sufficient to commit its transaction.

The initial implementation should prefer a small number of explicit validation paths rather than invent a generic health-check framework.

## Forwarding

IP forwarding must be enabled deliberately and validated at runtime.

HostKit should avoid unrelated sysctl tuning.

ROUTER owns only the kernel settings required for its routing role.

## NAT

NAT is router policy, not a generic host-security feature.

Masquerade/SNAT configuration must be tied to the intended WAN path and must not accidentally NAT unrelated interfaces.

Repeated execution must not duplicate NAT rules.

## DHCP and DNS

DHCP/DNS service is optional router functionality.

The initial implementation is expected to use dnsmasq where required.

ROUTER must bind services intentionally to the appropriate trusted interface/address and avoid unintentionally exposing DHCP/DNS service on WAN interfaces.

## Existing Routes and Addresses

ROUTER must inspect existing state before replacement.

It must distinguish between:

- state already matching the requested configuration
- compatible state that can be adopted
- conflicting state requiring explicit migration

Network state must not be treated as an empty canvas.

## Idempotency

Re-running ROUTER with the same requested configuration must converge.

It must not:

- duplicate addresses
- duplicate routes
- duplicate nftables rules
- duplicate dnsmasq configuration
- progressively rewrite unrelated network configuration

## Failure Behavior

Before APPLY, validation failure should leave the live network untouched.

After APPLY, failure of required runtime validation must trigger rollback while the rollback window remains armed.

ROUTER must clearly report whether:

- no live change occurred
- the new state was committed
- rollback was triggered
- rollback itself failed

Rollback failure is a critical error and must never be hidden behind a generic failure message.

## Deliberate Limits

The initial ROUTER product is not intended to become:

- a dynamic routing suite
- an SD-WAN controller
- a VPN orchestration framework
- a generic network-management system
- a replacement for FRR or similar routing software

Capabilities should be added only when a concrete HostKit router use case requires them.
