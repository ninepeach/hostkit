#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/tests/modules.sh"
"$ROOT_DIR/tests/limits.sh"
"$ROOT_DIR/tests/validators.sh"
"$ROOT_DIR/tests/build.sh"

printf 'OK all HostKit smoke tests passed\n'
