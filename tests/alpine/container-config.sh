#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
source "$ROOT_DIR/alpine/modules/container-config.sh"

d="$(mktemp -d)"
trap 'rm -rf "$d"' EXIT

cat >"$d/good" <<'EOF'
INOTIFY_MAX_USER_WATCHES=524288
INOTIFY_MAX_USER_INSTANCES=1024
INOTIFY_MAX_QUEUED_EVENTS=32768
SOMAXCONN=4096
NF_CONNTRACK_MAX=keep
EOF
container_config_parse "$d/good"
[ "$INOTIFY_MAX_USER_WATCHES" = 524288 ]
[ "$SOMAXCONN" = 4096 ]
[ "$NF_CONNTRACK_MAX" = keep ]

printf 'BOGUS=1\n' >"$d/bad"
! container_config_parse "$d/bad" >/dev/null 2>&1

printf 'SOMAXCONN=1\nSOMAXCONN=2\n' >"$d/dup"
! container_config_parse "$d/dup" >/dev/null 2>&1

printf 'OK container-config\n'
