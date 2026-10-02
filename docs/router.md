# ROUTER

> **Implementation status:** The v0.1 architecture below is the target contract. The current product entry point intentionally enables only the preserve-existing-uplink IPv4-forwarding path. NAT44/firewall renderers and isolated datapath tests exist, but persistent firewall ownership, LAN configuration, DHCP, PPPoE, and IPv6-PD are not released until they pass Debian 13 end-to-end validation.

ROUTER turns a Debian 13 physical machine into a simple home Internet router.

It is intentionally a home-router product, not a general-purpose Linux routing suite. ROUTER does not aim to provide BGP, OSPF, VRFs, SD-WAN, generic policy routing, VPN orchestration, or cloud-gateway management.

INIT is the recommended baseline on a fresh Debian 13 host, but it is not a prerequisite. ROUTER is a standalone entry point and establishes only the prerequisites required for its own contract.

## Router Model

The v0.1 target topology is deliberately small:

```text
Internet / ISP
      |
 DHCP / PPPoE
      |
    uplink
      |
  Debian 13
 HostKit ROUTER
      |
     LAN
      |
Switch / Wi-Fi AP
      |
 Home Devices
```

ROUTER targets one Internet uplink and one LAN.

Supported uplink cases are:

- an already-working Internet uplink that HostKit preserves
- DHCP
- PPPoE

Static WAN configuration is not a v0.1 requirement. If an existing static uplink already works, the no-configuration path may preserve it rather than taking ownership of it.

## Core Default Behavior

Running ROUTER without a configuration file is meaningful:

```text
debian13-router.sh
```

It means: make the current Debian host capable of acting as a home IPv4 router without unnecessarily taking ownership of its existing network configuration.

ROUTER should:

- detect the active Internet uplink from an unambiguous active default route
- preserve the uplink's current address and configuration method
- preserve existing IP addresses
- preserve existing routes
- preserve existing DNS configuration
- preserve existing DHCP server configuration
- enable IPv4 forwarding
- enable IPv4 NAT44 masquerade on the detected Internet uplink
- establish the router firewall policy required by the role

If the Internet uplink cannot be determined safely, ROUTER must refuse to guess rather than apply NAT to an arbitrary interface.

NAT uses interface-based masquerade rather than hard-coding the current uplink address so normal DHCP address changes do not invalidate the NAT rule.

## Configuration File

A configuration file is optional.

It is used when HostKit should actively configure network state rather than merely preserve the current uplink and enable routing.

The configuration format should remain a small, strict set of `KEY=VALUE` records. The file is data, not shell code, and must not be sourced as arbitrary shell.

The parser must accept only known keys and validate values before material changes.

A typical DHCP-uplink home router may be described as:

```text
UPLINK=eth0
UPLINK_MODE=dhcp

LAN=eth1
LAN_ADDRESS=192.168.10.1/24
DHCP_RANGE=192.168.10.100-192.168.10.200
```

A PPPoE uplink may be described as:

```text
UPLINK=eth0
UPLINK_MODE=pppoe
PPPOE_USER=user@example.com
PPPOE_SECRET_FILE=/root/pppoe.secret

LAN=eth1
LAN_ADDRESS=192.168.10.1/24
DHCP_RANGE=192.168.10.100-192.168.10.200
```

PPPoE passwords must not be passed as ordinary command-line arguments.

When ROUTER actively changes interface ownership or addressing, the target interface must be explicit. Automatic uplink detection is appropriate for preserving an already-working network, not for guessing which interface HostKit should reconfigure.

## IPv4

IPv4 is the baseline router path.

ROUTER owns:

- IPv4 forwarding for the router role
- NAT44 masquerade
- forwarding firewall policy
- LAN gateway behavior when LAN configuration is requested

IPv4 forwarding is enabled by the ROUTER role.

NAT44 is enabled by default and tied to the effective Internet-facing interface.

For a normal DHCP uplink, the physical uplink and effective WAN interface are normally the same interface.

For PPPoE, the physical uplink and logical WAN are different concepts:

```text
physical uplink: eth0
PPPoE session:   ppp0
effective WAN:   ppp0
```

NAT must follow the effective WAN interface rather than incorrectly masquerading on the underlying Ethernet interface.

## LAN DHCP and DNS

ROUTER uses dnsmasq for the small home-LAN DHCPv4 and DNS role.

LAN DHCP/DNS is not enabled merely because ROUTER was run without configuration.

An explicit DHCP range means HostKit should provide the normal home-LAN service:

```text
DHCP_RANGE=192.168.10.100-192.168.10.200
```

When HostKit manages this LAN service:

- DHCPv4 binds only to the intended trusted LAN
- the default router handed to clients is the LAN gateway address
- dnsmasq provides local forwarding/caching DNS
- the DNS server handed to clients is the router's LAN address
- upstream DNS follows the usable WAN resolver state unless a future demonstrated requirement justifies an explicit override

ROUTER must not guess a DHCP pool from the LAN subnet.

The absence of a HostKit DHCP range means ROUTER does not create a new LAN DHCP/DNS service. It does not imply that unrelated pre-existing DHCP/DNS configuration should be deleted.

## IPv6

IPv6 is part of the home-router model, but it follows native IPv6 semantics rather than copying the IPv4 NAT design.

ROUTER should support ISP-provided IPv6 where the uplink makes it available, including the mechanisms required for normal home broadband such as router advertisements and DHCPv6 prefix delegation.

When the ISP delegates a usable prefix, ROUTER should:

- enable the required IPv6 forwarding
- assign/use an appropriate LAN prefix
- advertise the LAN prefix to clients
- allow normal SLAAC behavior
- apply IPv6 firewall policy

IPv6 does not use NAT66 by default.

Conceptually:

```text
IPv4
LAN -> NAT44 -> WAN

IPv6
ISP delegated prefix -> ROUTER -> LAN /64 -> RA/SLAAC -> clients
```

If the ISP does not provide a usable delegated prefix, ROUTER must not invent a global IPv6 prefix or silently introduce NAT66. IPv4 routing continues to operate normally.

The exact Debian 13 behavior for DHCPv6-PD and RA must be validated during implementation, particularly for both DHCP and PPPoE uplinks.

## Implementation Components

The v0.1 implementation should remain small:

```text
systemd-networkd
    owned WAN/LAN network configuration
    DHCP client behavior
    IPv6 RA / DHCPv6-PD integration where validated

ppp
    PPPoE

dnsmasq
    LAN DHCPv4
    local DNS forwarding/cache

nftables
    host/router firewall
    forwarding policy
    NAT44

Linux kernel
    IPv4/IPv6 forwarding
```

HostKit should not add Kea, Unbound, radvd, FRR, or a backend abstraction merely to anticipate future requirements.

If Debian 13 validation proves that one of these small component boundaries is insufficient, the implementation may be revised based on that concrete requirement.

## Independence from SECURITY

ROUTER must work when SECURITY is absent.

If SECURITY already exists, ROUTER preserves its host-management policy.

If SECURITY is absent, ROUTER establishes only the minimum host protection necessary to operate safely and recoverably.

ROUTER must not silently:

- create an administrative user
- change sudo policy
- change SSH ports or authentication policy
- replace authorized_keys

Shared mechanisms are reused through modules rather than by invoking SECURITY or INIT as prerequisites.

## Firewall Responsibilities

ROUTER owns router-specific policy, including:

- FORWARD behavior
- IPv4 NAT44
- IPv4 and IPv6 forwarding policy
- INPUT requirements for router-owned LAN services such as DHCP and DNS

SECURITY owns host-management policy when present.

The implementation must compose these policies predictably and must not rely on execution order to avoid accidental rule loss.

The exact nftables file/chain layout should remain simple and is an implementation decision until validated on Debian 13.

## Network Ownership and Safety

ROUTER must inspect existing addresses, routes, services, firewall state, and network ownership before replacement.

The no-configuration path deliberately preserves existing network configuration.

When a configuration file requests that HostKit actively configure an interface, ROUTER must detect the existing network-management environment before taking ownership.

It must not blindly disable or mask NetworkManager, ifupdown, systemd-networkd, or another manager.

When existing ownership conflicts with requested HostKit configuration, ROUTER must either perform an explicitly requested, transactionally protected migration or refuse and explain the conflict.

Network state must not be treated as an empty canvas.

## Critical Changes and Transactions

A syntactically valid network configuration can still make a machine unreachable.

Changes to addresses, routes, interface ownership, forwarding, or firewall policy require transactional protection when they can affect reachability.

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

ROUTER owns its own runtime success criteria rather than reusing SECURITY's SSH verification rule.

## Idempotency

Re-running ROUTER with the same requested state must converge.

It must not:

- duplicate addresses
- duplicate routes
- duplicate nftables rules
- duplicate DHCP/DNS configuration
- progressively rewrite unrelated network configuration

## Failure Behavior

Before APPLY, validation failure should leave the live network untouched.

After APPLY, failure of required runtime validation must trigger rollback while the rollback window remains armed.

ROUTER must clearly report whether no live change occurred, the new state was committed, rollback was triggered, or rollback itself failed.

Rollback failure is a critical error.

## Deliberate Limits

ROUTER v0.1 does not aim to provide:

- Multi-WAN
- BGP or OSPF
- VRFs
- SD-WAN
- generic policy routing
- VPN orchestration
- cloud gateway management
- generic network-management abstractions

VLANs, bonding, additional LANs, static-WAN ownership, advanced DHCP/DNS behavior, and other features should be added only when a concrete HostKit home-router use case requires them.
