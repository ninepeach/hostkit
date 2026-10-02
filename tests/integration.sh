#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

for test_file in "$ROOT_DIR"/tests/integration/*.sh; do
    printf 'Running integration test: %s\n' "$(basename "$test_file")"
    bash "$test_file"
done
