#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/tests/module.sh" all
"$ROOT_DIR/tests/build.sh"
"$ROOT_DIR/tests/alpine.sh"

printf 'OK all HostKit tests passed\n'
