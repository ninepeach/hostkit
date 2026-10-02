#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/tools/build.sh" init
artifact="$ROOT_DIR/dist/debian13-init.sh"

test -x "$artifact"
bash -n "$artifact"

grep -q '^# Product: INIT$' "$artifact"
grep -q '^# Platform: Debian 13$' "$artifact"
grep -q '^set -Eeuo pipefail$' "$artifact"
grep -q '^hostkit_main "\$@"$' "$artifact"

for module in core apt packages limits locale hostname timezone network-tools chrony unattended-upgrades system-health; do
    count="$(grep -c "^# ---- module: $module ----$" "$artifact")"
    if [ "$count" -ne 1 ]; then
        printf 'ERROR module %s occurs %s times in generated artifact\n' "$module" "$count" >&2
        exit 1
    fi
done

printf 'OK build smoke test passed\n'
