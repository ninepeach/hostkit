# GATEWAY

GATEWAY configures a Debian 13 host to operate as an upstream/downstream network gateway.

It is intentionally narrower than a general-purpose router. GATEWAY does not aim to provide dynamic routing, BGP, OSPF, VRFs, SD-WAN, or generic network orchestration.

INIT is the recommended baseline on a fresh Debian 13 host, but it is not a prerequisite. GATEWAY is a standalone entry point and establishes only the prerequisites required for its own contract.

## Gateway Model

The initial model has:

- one selected uplink
- one selected LAN/downstream interface
- forwarding between the required paths
- NAT/masquerade by default
- local DNS by default
- optional DHCP server

Initial uplink modes are expected to include:

- DHCP client
- static addressing
- PPPoE

These modes describe how the gateway reaches its upstream network. DHCP server on the LAN is a separate optional capability.

## Responsibilities

GATEWAY may manage:

- uplink interface and addressing
- LAN interface and addressing
- routes required by the gateway role
- IP forwarding
- gateway firewall policy
- NAT/masquerade
- local DNS service
- optional LAN DHCP server
- gateway-specific runtime validation

Initial Debian 13 implementation choices are expected to use:

- systemd-networkd for owned interface configuration
- nftables for firewall and NAT
- a small dedicated DNS/DHCP implementation selected for the GATEWAY product
- Debian PPP/PPPoE facilities where PPPoE is requested

Exact package choices remain implementation decisions until validated on Debian 13.

## Default Policy

GATEWAY defaults are deliberately opinionated because the product represents a gateway role:

```text
IP forwarding    ON
NAT              ON
Local DNS        ON
DHCP server      OFF
```

DHCP server becomes enabled when an explicit DHCP range is configured.

GATEWAY must not guess a DHCP pool from the LAN subnet. An administrator may have reserved static-address space that HostKit cannot infer.

Local DNS is enabled by default but may be explicitly disabled.

## DHCP

When DHCP server service is requested, the configuration must explicitly identify at least:

- trusted LAN interface/address
- DHCP range

The default router/gateway option handed to clients should be the configured LAN gateway address unless explicitly overridden.

When local DNS is enabled, the default DNS server handed to DHCP clients should be the gateway's LAN address unless explicitly overridden.

DHCP must bind only to the intended trusted LAN side.

The absence of a DHCP range means GATEWAY does not provide DHCP server service.

## DNS

Local DNS is part of the default gateway role.

The DNS service should:

- listen only on intended local/trusted addresses
- never become an unintended open resolver on the uplink
- provide recursive forwarding/caching appropriate for a small gateway
- use sane upstream resolver behavior
- remain independently disableable

DNS and DHCP are separate capabilities even if one implementation package can provide both.

## Forwarding

GATEWAY owns forwarding policy.

INIT does not enable forwarding on GATEWAY's behalf.

GATEWAY enables and validates the kernel forwarding state required by the requested gateway role.

HostKit should avoid unrelated sysctl tuning.

## NAT

NAT is enabled by default for the initial gateway role.

Masquerade/SNAT configuration must be tied to the selected uplink and intended downstream source network. It must not accidentally NAT unrelated interfaces or networks.

Repeated execution must not duplicate NAT rules.

A future explicit no-NAT mode may be added when a demonstrated routed-gateway use case requires it; v0.1 should not grow speculative modes.

## Independence from SECURITY

GATEWAY must work when SECURITY is absent.

If SECURITY already exists, GATEWAY preserves its host-management policy.

If SECURITY is absent, GATEWAY establishes only the minimum host protection necessary to operate safely and recoverably.

GATEWAY must not silently:

- create an administrative user
- change sudo policy
- change SSH ports or authentication policy
- replace authorized_keys

Shared mechanisms are reused through modules rather than by invoking SECURITY or INIT as prerequisites.

## Firewall Responsibilities

GATEWAY owns gateway-specific policy, including:

- FORWARD behavior
- NAT
- INPUT requirements for gateway services such as DNS and DHCP on trusted interfaces

SECURITY owns host-management policy when present.

The implementation must compose these policies predictably and must not rely on execution order to avoid accidental rule loss.

The exact nftables file/chain layout should remain simple and is an implementation decision until validated on Debian 13.

## Network Manager Safety

GATEWAY must detect the existing network-management environment before taking ownership of interfaces.

It must not blindly disable or mask NetworkManager, ifupdown, systemd-networkd, or another manager simply because HostKit prefers one implementation.

When existing ownership conflicts with the requested gateway configuration, GATEWAY must either:

- perform an explicitly requested migration with rollback, or
- refuse and explain the conflict

Ambiguous destructive migration is not acceptable.

## Network Changes Are Critical

A syntactically valid network configuration can still make a remote machine unreachable.

Changes to management addresses, routes, interface ownership, forwarding, or firewall policy therefore require transactional protection when they can affect reachability.

The generic transaction mechanism can be shared with SECURITY, but GATEWAY owns its own success criteria.

## Transaction Model

GATEWAY uses the common transaction lifecycle:

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
GATEWAY-SPECIFIC VALIDATE
  |
COMMIT
  |
DISARM ROLLBACK
```

Rollback must restore the relevant previous network and firewall state and must not depend on the initiating SSH session surviving.

## Verification

GATEWAY must not blindly reuse SECURITY's SSH verification rule.

Examples:

- changing a LAN management address may require validation through the new address
- changing uplink configuration may require upstream connectivity validation
- enabling forwarding requires forwarding-path validation
- DHCP/DNS roles require service and binding validation

A successful ping alone is not universal proof that a gateway configuration is correct.

Each critical operation must define what evidence is sufficient to commit its transaction.

The initial implementation should prefer a small number of explicit validation paths rather than invent a generic health-check framework.

## Existing State

GATEWAY must inspect existing addresses, routes, services, firewall state, and network ownership before replacement.

It must distinguish between:

- state already matching the requested configuration
- compatible state that can be adopted
- conflicting state requiring explicit migration
- ambiguous state that should fail safely

Network state must not be treated as an empty canvas.

## Idempotency

Re-running GATEWAY with the same requested configuration must converge.

It must not:

- duplicate addresses
- duplicate routes
- duplicate nftables rules
- duplicate DHCP/DNS configuration
- progressively rewrite unrelated network configuration

## Failure Behavior

Before APPLY, validation failure should leave the live network untouched.

After APPLY, failure of required runtime validation must trigger rollback while the rollback window remains armed.

GATEWAY must clearly report whether:

- no live change occurred
- the new state was committed
- rollback was triggered
- rollback itself failed

Rollback failure is a critical error and must never be hidden behind a generic failure message.

## Deliberate Limits

The initial GATEWAY product is not intended to become:

- a dynamic routing suite
- an SD-WAN controller
- a VPN orchestration framework
- a generic network-management system
- a replacement for FRR or similar routing software

Capabilities should be added only when a concrete HostKit gateway use case requires them.
