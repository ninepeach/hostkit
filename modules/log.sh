#!/usr/bin/env bash
set -euo pipefail
info(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*" >&2; }
die(){ echo "[ERROR] $*" >&2; exit 1; }
assert_root(){ [[ $EUID -eq 0 ]] || die "Run as root"; }
