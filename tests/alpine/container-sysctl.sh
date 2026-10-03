#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/container-config.sh"
source "$ROOT_DIR/alpine/modules/container-sysctl.sh"

d="$(mktemp -d)"
trap 'rm -rf "$d"' EXIT
container_config_reset
INOTIFY_MAX_USER_WATCHES=524288
SOMAXCONN=4096
out="$(container_sysctl_render)"
grep -q '^fs.inotify.max_user_watches = 524288$' <<<"$out"
grep -q '^net.core.somaxconn = 4096$' <<<"$out"
! grep -q 'nf_conntrack_max' <<<"$out"

HOSTKIT_CONTAINER_SYSCTL_FILE="$d/hostkit.conf"
export HOSTKIT_CONTAINER_SYSCTL_FILE
container_sysctl_install
container_sysctl_hostkit_owned "$d/hostkit.conf"
before="$(sha256sum "$d/hostkit.conf")"
container_sysctl_install
after="$(sha256sum "$d/hostkit.conf")"
[ "$before" = "$after" ]

printf 'foreign\n' >"$d/foreign.conf"
HOSTKIT_CONTAINER_SYSCTL_FILE="$d/foreign.conf"
! container_sysctl_install >/dev/null 2>&1

mkdir -p "$d/bin"
cat >"$d/bin/rc-update" <<EOF
#!/usr/bin/env sh
printf '%s\\n' "\$*" >"$d/rc-update.args"
EOF
chmod +x "$d/bin/rc-update"
PATH="$d/bin:$PATH"
export PATH
container_sysctl_enable_boot
[ "$(cat "$d/rc-update.args")" = "add sysctl boot" ]

printf 'OK container-sysctl\n'
