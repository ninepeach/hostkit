#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/container-capabilities.sh"

d="$(mktemp -d)"
trap 'rm -rf "$d"' EXIT
mkdir -p "$d/sys/user"
cat >"$d/filesystems" <<'EOF'
nodev	cgroup2
nodev	overlay
EOF
for key in max_mnt_namespaces max_net_namespaces max_pid_namespaces max_uts_namespaces; do
    printf '1024\n' >"$d/sys/user/$key"
done
HOSTKIT_PROC_ROOT="$d"
export HOSTKIT_PROC_ROOT

container_capability_cgroup2
container_capability_overlay
container_capability_namespaces
container_capabilities_report

printf '0\n' >"$d/sys/user/max_net_namespaces"
! container_capability_namespaces

printf 'OK container-capabilities\n'
