# Alpine CONTAINER

Alpine CONTAINER is a small build-time profile for an Alpine Linux image whose host purpose is to run containers.

It configures the host image. It does **not** manage containers.

## Boundary

Owned by HostKit:

- explicit, allow-listed kernel/sysctl tuning requested by the image builder
- inspection of cgroup v2, overlayfs, and namespace capabilities
- one HostKit-owned sysctl drop-in
- deterministic validation and exit status

Not owned by HostKit:

- Docker, containerd, Podman, or Kubernetes installation
- container images or application deployment
- Compose, Helm, Swarm, GitOps, registries, or workload configuration
- runtime network creation
- workload-specific memory, TCP, or conntrack guesses

## Configuration

Every tuning value is explicit. Use `keep` to preserve the kernel/default policy.

```text
INOTIFY_MAX_USER_WATCHES=524288
INOTIFY_MAX_USER_INSTANCES=1024
INOTIFY_MAX_QUEUED_EVENTS=32768
SOMAXCONN=keep
NF_CONNTRACK_MAX=keep
```

The numeric values above are an example, not HostKit defaults.

Supported keys:

- `INOTIFY_MAX_USER_WATCHES`
- `INOTIFY_MAX_USER_INSTANCES`
- `INOTIFY_MAX_QUEUED_EVENTS`
- `SOMAXCONN`
- `NF_CONNTRACK_MAX`

HostKit intentionally does not set `file-max`, swap, overcommit, TCP timeout, dirty-page, scheduler, or other generic "performance tuning" values without a concrete workload requirement.

## Build and use

```bash
./tools/build.sh alpine container
./dist/alpine-container.sh --check container.conf
./dist/alpine-container.sh container.conf
```

`--check` validates the configuration, requested sysctl availability, and host kernel capabilities without writing persistent tuning.

Apply mode writes only:

```text
/etc/sysctl.d/90-hostkit-container.conf
```

The file carries a HostKit ownership marker. A foreign file at that path is never overwritten.

The profile does not call `sysctl -w`. It is intended for image construction: persistent values become effective through the normal host sysctl lifecycle after the image boots.

## Required VM validation

Before describing this profile as production-ready, validate on the target Alpine image/kernel:

- cgroup v2 support and actual mount/delegation behavior
- overlayfs support with the intended container runtime
- namespace availability
- Alpine sysctl boot-time loading of the HostKit drop-in
- reboot convergence
- runtime-specific storage and networking behavior
- representative container workload under resource pressure

These checks must drive future tuning. HostKit does not add parameters merely because they are common in internet tuning lists.
