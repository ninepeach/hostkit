# Conventions

This document defines behavior shared by all HostKit products.

The goal is consistency: INIT, SECURITY, and ROUTER should not invent different meanings for the same operational concept.

## Command-Line Interface

HostKit favors a small, explicit CLI.

Rules:

- options must have one clear meaning
- defaults must be safe
- destructive behavior must never be the default
- unknown options must fail
- invalid values must fail before material changes
- options must not silently override one another
- product-specific options belong to that product

HostKit should not add flags merely because they may be useful someday.

## Exit Status

Unless a more specific contract is documented:

- exit 0 means the requested state was established successfully
- non-zero means the requested operation did not complete successfully

Warnings do not by themselves require a non-zero exit status when the requested state is otherwise established.

Critical validation failure, apply failure, rollback failure, unsupported platform, or invalid input must return non-zero.

A script must never print a final success status and then exit non-zero, or print failure and then exit zero.

## Output Levels

HostKit uses a small set of human-readable levels:

```text
INFO
WARN
ERROR
OK
```

Meaning:

- **INFO** — an operation or observed state
- **WARN** — non-fatal condition that deserves operator attention
- **ERROR** — required operation or invariant failed
- **OK** — validation or operation completed successfully

Output should be concise enough to remain readable over SSH.

Debug tracing is not normal user output.

## Final Summary

Each product should finish with a compact summary of observed state.

The summary must reflect actual validation results rather than merely echo completed commands.

If a critical step failed, the product must not produce an overall successful status.

## Dry Run

If a product implements `--dry-run`, dry-run means:

- inspect current state
- parse and validate requested input
- report intended material changes
- perform static validation that does not require applying those changes
- do not modify the live host

Dry-run must not claim that runtime validation succeeded when no live state was changed.

Dry-run must not:

- create users
- modify files
- change services
- change firewall state
- change routes or addresses
- enable forwarding
- install or remove packages

If a meaningful dry-run cannot be implemented for an operation, HostKit should report that limitation rather than simulate false certainty.

## Idempotency

HostKit products are convergent.

Running the same product repeatedly with the same requested state should not produce progressively different host state.

A repeated run must not unnecessarily:

- append duplicate configuration
- duplicate authorized keys
- duplicate repositories
- duplicate firewall rules
- duplicate addresses or routes
- restart services that do not require restart
- rewrite files solely to change formatting

Idempotency does not mean every command must be skipped. It means the resulting state is stable and repeated execution is safe.

## Inspect Before Mutate

Before replacing or removing existing configuration, HostKit must inspect enough state to determine whether it is:

- already correct
- compatible and adoptable
- conflicting
- unknown or ambiguous

Ambiguous destructive changes must fail safely or require explicit intent.

The live system must not be treated as an empty canvas.

## Managed Files

HostKit should prefer dedicated files or drop-ins over editing unrelated administrator-owned configuration.

A HostKit-owned file should be clearly identifiable as managed by HostKit.

When practical, generated managed files should include a short header such as:

```text
# Managed by HostKit. Do not edit manually.
```

This marker establishes ownership; it does not justify overwriting arbitrary files with the same path.

Before replacing an existing path, HostKit must determine whether it already owns that path or whether explicit migration is required.

## Preserve Unrelated Configuration

HostKit owns only the state required by the selected product.

It must avoid rewriting unrelated configuration merely to normalize formatting or impose stylistic preferences.

Where a native drop-in mechanism exists and is sufficient, prefer it over wholesale replacement.

## Static Validation

Static validation happens before APPLY.

Examples include:

- OpenSSH configuration syntax validation
- sudoers syntax validation
- nftables syntax validation
- configuration-file parsing
- input validation

Passing static validation means only that the staged configuration is syntactically or structurally acceptable.

It does not prove that the resulting host will remain reachable or operational.

## Runtime Validation

Runtime validation happens after APPLY.

It verifies the resulting live state.

Examples include:

- service active state
- chrony synchronization state
- effective firewall state
- network address and route state
- forwarding state
- DHCP/DNS binding
- successful new authenticated SSH session

Products define their own runtime success criteria.

## Transaction Terminology

A critical HostKit transaction uses these terms consistently:

### BACKUP

Capture enough pre-change state to restore the parts that the transaction may mutate.

### STAGE

Prepare the desired configuration without changing the live critical state.

### STATIC VALIDATE

Validate staged configuration before activation.

### ARM ROLLBACK

Schedule an independent recovery action before making the critical live change.

### APPLY

Activate the staged change.

### RUNTIME / EXTERNAL VALIDATE

Verify the resulting live behavior using product-specific evidence.

### COMMIT

Accept the new live state after successful validation.

### DISARM ROLLBACK

Cancel the pending recovery action only after commit is complete.

### ROLLBACK

Restore the registered pre-transaction state after failure, timeout, or explicit rejection.

## Rollback Independence

A rollback mechanism for remote critical changes must not depend on:

- the initiating SSH connection remaining alive
- the initiating shell continuing to run
- an interactive terminal remaining attached

A background `sleep` process in the current shell is not sufficient as the sole safety mechanism.

The Debian 13 implementation should use a system-managed mechanism where appropriate.

## Rollback Completeness

Rollback must restore the relevant pre-transaction state, not merely copy back a preferred configuration file.

Depending on the transaction, restore data may include:

- previous file contents
- whether a file previously existed
- service runtime state
- service enabled/disabled state
- active nftables state
- network runtime state

Every critical mutation must be registered deliberately.

If HostKit cannot restore all state it changed, it must not describe that operation as fully transactional.

## Rollback Failure

Rollback failure is a critical error.

It must be reported distinctly from the original apply or validation failure.

HostKit must not hide rollback failure behind a generic error message.

## Interactive and Non-Interactive Execution

Interactive confirmation is not a substitute for runtime verification.

For example, typing `y` in an existing SSH session does not prove that new SSH connections work.

When a product requires runtime evidence, the same safety requirement applies whether execution is interactive or non-interactive.

If a non-interactive environment cannot provide the required safe verification path, the product should fail safely rather than silently weaken the contract.

## Confirmation

A human confirmation may be used when the product-specific safety model explicitly permits it, such as trusted local-console execution.

Confirmation must never be interpreted as evidence for a condition the operator has not actually demonstrated.

## Remote Management Path

A product that changes remote management must preserve the old management path until the replacement path has been independently verified whenever that is technically possible.

Core invariant:

> Never destroy the old management path before the replacement path has been independently verified.

This principle takes precedence over cosmetic cleanup.

## Build Definitions

Build definitions are simple composition files, not a HostKit-specific language.

They should declare required modules using ordinary shell structures, for example:

```bash
MODULES=(
    apt
    packages
    chrony
)
```

HostKit should not introduce comment directives such as:

```text
# require_module: ...
```

or another custom dependency DSL.

## Build Tool

`tools/build.sh` is a deterministic composition tool.

Its responsibilities are limited to:

- validate requested build definition and modules
- concatenate the required source in deterministic order
- add generated-file metadata
- write the standalone artifact
- fail if required input is missing or invalid

It must not evolve into:

- a dependency resolver
- a plugin loader
- an inventory system
- a package manager
- a general build framework

## Generated Artifacts

Files under `dist/` are generated artifacts.

A generated distribution script should:

- be standalone
- identify itself as generated
- identify the HostKit product and target platform
- contain no runtime dependency on the source tree
- be auditable as plain shell
- fail early on unsupported platforms

Generated files should not be edited manually.

## Shell Behavior

HostKit shell code should favor explicit failure handling.

`set -Eeuo pipefail` may be used as a baseline, but it is not a substitute for deliberate validation and error handling.

Expected failures that are part of normal control flow must be handled explicitly.

Cleanup and rollback paths must not be accidentally aborted by strict-shell behavior.

## Reboots

HostKit does not automatically reboot a host unless a future product explicitly documents that behavior and requires explicit operator intent.

INIT does not automatically reboot after unattended upgrades.

## Scope Discipline

Shared conventions exist only for behavior genuinely shared by multiple products.

Do not create an abstraction merely because two pieces of code look temporarily similar.

When an explicit small implementation is easier to audit than a generic framework, prefer the explicit implementation.
