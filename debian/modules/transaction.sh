# Confirmed-transaction mechanisms.
# Product-specific backup and rollback commands remain product-owned.

transaction_validate_timeout() {
    local value="$1"
    case "$value" in ''|*[!0-9]*) return 1 ;; esac
    [ "$value" -ge 30 ] && [ "$value" -le 3600 ]
}

transaction_begin() {
    local name="$1"
    [ -n "$name" ] || { die "Transaction name is required."; return 1; }
    HOSTKIT_TRANSACTION_NAME="$name"
    HOSTKIT_TRANSACTION_ARMED=0
    HOSTKIT_TRANSACTION_UNIT=
}

transaction_arm() {
    local rollback_script="$1"
    local timeout="${2:-180}"

    transaction_validate_timeout "$timeout" || { die "Invalid rollback timeout: $timeout"; return 1; }
    [ -x "$rollback_script" ] || { die "Rollback script is not executable: $rollback_script"; return 1; }
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 0 ] || { die "Transaction is already armed."; return 1; }

    local unit="hostkit-rollback-${HOSTKIT_TRANSACTION_NAME}-$$"
    systemd-run --unit="$unit" --on-active="${timeout}s" --collect "$rollback_script" >/dev/null
    HOSTKIT_TRANSACTION_UNIT="$unit"
    HOSTKIT_TRANSACTION_ARMED=1
}

transaction_disarm() {
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 1 ] || return 0
    systemctl stop "${HOSTKIT_TRANSACTION_UNIT}.timer" >/dev/null 2>&1 || true
    systemctl stop "${HOSTKIT_TRANSACTION_UNIT}.service" >/dev/null 2>&1 || true
    systemctl reset-failed "${HOSTKIT_TRANSACTION_UNIT}.service" >/dev/null 2>&1 || true
    HOSTKIT_TRANSACTION_ARMED=0
}

transaction_commit() {
    transaction_disarm
}

transaction_rollback() {
    local rollback_script="$1"
    [ -x "$rollback_script" ] || { die "Rollback script is not executable: $rollback_script"; return 1; }
    transaction_disarm
    "$rollback_script"
}
