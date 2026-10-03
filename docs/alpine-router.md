# Alpine ROUTER

Alpine ROUTER is an independent HostKit implementation for a small VM router appliance.

## Scope

The first release targets:

- one WAN
- one LAN
- DHCP or PPPoE WAN
- static IPv4 LAN address
- IPv4 forwarding
- NAT44 masquerade
- stateful forwarding firewall
- dnsmasq DHCPv4/DNS

Tailscale is outside HostKit ownership. Install, authenticate, and configure it separately.

## Configuration

Example DHCP WAN configuration:

```text
UPLINK=eth0
UPLINK_MODE=dhcp
LAN=eth1
LAN_ADDRESS=192.168.50.1/24
DHCP_RANGE=192.168.50.100-192.168.50.200
```

PPPoE additionally requires an explicit username and a root-readable external secret file. HostKit does not place the password in the router configuration.

## Safety

The current source contains render, validation, ownership, and persistence mechanisms, but configured live network takeover remains disabled until Alpine VM validation proves the OpenRC/ifupdown-ng, dnsmasq, nftables, PPPoE, restart, and rollback lifecycle.

HostKit must not replace an existing administrator-owned network, dnsmasq, nftables, or PPP configuration file.

## Tailscale

Tailscale is intentionally independent:

```text
HostKit ROUTER -> network/router ownership
Tailscale       -> manually installed and managed
```

HostKit does not run `tailscale up`, manage auth keys, change tailnet policy, or provide a resident agent.
