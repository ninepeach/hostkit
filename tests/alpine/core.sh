#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/alpine/modules/core.sh"
require_command sh
if require_command hostkit-command-that-does-not-exist 2>/dev/null; then
    echo "ERROR missing command accepted" >&2; exit 1
fi
echo "OK alpine core"
