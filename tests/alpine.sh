#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for test_file in "$ROOT_DIR"/tests/alpine/*.sh; do
    printf 'Testing Alpine: %s\n' "$(basename "$test_file" .sh)"
    bash "$test_file"
done
"$ROOT_DIR/tools/build.sh" alpine router
bash -n "$ROOT_DIR/dist/alpine-router.sh"
printf 'OK Alpine tests passed\n'
