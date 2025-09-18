#!/usr/bin/env bash
set -euo pipefail
info(){ echo "[INFO] $*"; }
warn(){ echo "[WARN] $*" >&2; }
die(){ echo "[ERROR] $*" >&2; exit 1; }