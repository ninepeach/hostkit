# SECURITY

SECURITY establishes safe administrative access and host-level protection.

Its responsibilities are deliberately grouped because user identity, sudo, SSH, and firewall policy form one management-access chain.

```text
Host Firewall -> SSH -> Admin User -> sudo -> root privilege
```

A mistake anywhere in this chain can lock an administrator out. SECURITY therefore treats access-changing operations as a single safety domain.

## Responsibilities

SECURITY may manage:

- administrative user creation or validation
- sudo access
- SSH server configuration
- authorized_keys
- host nftables policy
- transactional protection and rollback
- end-to-end verification of new remote access

SECURITY does not configure routing, forwarding, NAT, DHCP, or router topology.

## Existing State

SECURITY must preserve unrelated administrator configuration where practical.

HostKit should prefer dedicated managed files and drop-ins, including mechanisms such as:

```text
/etc/ssh/sshd_config.d/
/etc/sudoers.d/
```

It must not replace an entire configuration file when a dedicated HostKit-owned fragment can express the intended state safely.

## Administrative User

User creation is an explicit security operation, not part of INIT.

SECURITY must distinguish:

- an existing valid user
- a missing user that may be created
- an existing incompatible account state

It must not silently repurpose an unrelated account.

## sudo

sudo policy belongs to SECURITY.

HostKit-managed sudo configuration must be isolated where practical and syntax-validated before activation.

A sudo change must not remove the current recovery path before the replacement path has been validated.

## SSH

SSH configuration must be staged and statically validated before activation.

At minimum, OpenSSH configuration changes must pass the server's configuration validation before reload/restart.

SECURITY should prefer reload over disruptive restart when the required change permits it.

Existing SSH sessions are not proof that the resulting configuration accepts new sessions.

## SSH Recovery Invariant

HostKit's host firewall keeps TCP port 22 allowed as a conservative recovery invariant.

If the configured SSH service uses another port, the firewall may allow both:

```text
22/tcp
configured-ssh-port/tcp
```

This does not require sshd to listen on port 22.

HostKit v0.1 does not provide a convenience option whose purpose is to remove this recovery invariant.

## Host Firewall

SECURITY owns host-management firewall policy.

Baseline principles:

- accept loopback
- accept established/related traffic
- permit required ICMP
- permit required ICMPv6
- permit management access
- permit explicitly configured additional services
- default-deny unsolicited INPUT
- allow OUTPUT unless a future requirement justifies a different policy

HostKit uses nftables directly.

It does not layer UFW, firewalld, or iptables compatibility management on top.

## Router Composition

SECURITY and ROUTER are composable.

SECURITY may be applied before or after ROUTER.

SECURITY must not destroy ROUTER-owned forwarding, NAT, or router-specific policy.

ROUTER must not destroy SECURITY-owned host-management policy.

ROUTER does not require SECURITY to have been run.

## Critical Transaction

Changes capable of breaking administrative access must be transactional.

Required lifecycle:

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
EXTERNAL VALIDATE
  |
COMMIT
  |
DISARM ROLLBACK
```

Rollback must survive loss of the SSH session that started SECURITY.

A shell background process tied to the initiating session is not sufficient as the only rollback mechanism.

The Debian 13 implementation should use a system-managed mechanism such as a transient systemd unit/timer where appropriate.

The initial default rollback window is 180 seconds.

The implementation may later expose a bounded timeout option, but safety must remain the default.

## Rollback Scope

Rollback restores the relevant pre-transaction state.

That can include:

- previous files
- removal of files newly created by the transaction
- service runtime state
- service enabled/disabled state
- active nftables state

Restoring only one configuration file is not sufficient when the transaction changed multiple parts of the access chain.

Every critical mutation must therefore be registered deliberately with the transaction.

## External Verification

For a remotely initiated SECURITY change, commit requires proof that the new management path works.

The existing SSH connection does not qualify.

The preferred proof is a **new authenticated SSH session established after APPLY**.

If SECURITY configures SSH on port 10220:

```text
new authenticated session on server port 10220 -> qualifies
new session on server port 22                  -> does not verify 10220
old session remains connected                  -> does not qualify
TCP connection without authentication          -> does not qualify
```

The server-side SSH port is the primary signal.

Additional safeguards may include:

- session creation time after transaction APPLY
- expected administrative user
- original client address when SECURITY itself was invoked over SSH

These are guards, not substitutes for successful authentication.

The exact Debian 13/OpenSSH mechanism used to observe a newly authenticated session must be tested before implementation and must not rely solely on seeing an ESTABLISHED TCP socket.

## Local Console Execution

When SECURITY is run from a trusted local or hypervisor console, an external SSH session may not be the appropriate commit signal.

The implementation may provide an explicit confirmation path for this case.

Remote and local verification must remain clearly distinguishable.

## Non-Interactive Execution

HostKit must not silently bypass rollback or external verification merely because no interactive terminal is available.

If a safe confirmation path cannot be established, SECURITY should fail safely rather than guess.

Any future escape hatch that disables rollback must be explicit, difficult to invoke accidentally, and justified by a real operational need.

## Idempotency

Re-running SECURITY must converge on the requested policy.

It must not:

- duplicate authorized keys
- append repeated sshd directives
- duplicate sudo rules
- duplicate nftables rules
- progressively weaken access policy

A no-op run on an already-correct host should remain a no-op wherever practical.
