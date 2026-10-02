# Confirmed-transaction mechanisms.
# Product-specific backup, health verification, and rollback content remain product-owned.

transaction_validate_timeout() {
    local value="$1"
    case "$value" in ''|*[!0-9]*) return 1 ;; esac
    [ "$value" -ge 30 ] && [ "$value" -le 3600 ]
}

transaction_validate_name() {
    local value="$1"
    [ -n "$value" ] &&
        [ "${#value}" -le 48 ] &&
        printf '%s' "$value" | grep -Eq '^[a-z0-9][a-z0-9_-]*$'
}

transaction_begin() {
    local name="$1"
    transaction_validate_name "$name" || { die "Invalid transaction name: $name"; return 1; }
    HOSTKIT_TRANSACTION_NAME="$name"
    HOSTKIT_TRANSACTION_ARMED=0
    HOSTKIT_TRANSACTION_UNIT=
    HOSTKIT_TRANSACTION_ROLLBACK=
}

transaction_arm() {
    local rollback_script="$1"
    local timeout="${2:-180}"

    [ -n "${HOSTKIT_TRANSACTION_NAME:-}" ] || { die "Transaction has not been started."; return 1; }
    transaction_validate_timeout "$timeout" || { die "Invalid rollback timeout: $timeout"; return 1; }
    [ -x "$rollback_script" ] || { die "Rollback script is not executable: $rollback_script"; return 1; }
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 0 ] || { die "Transaction is already armed."; return 1; }

    local unit="hostkit-rollback-${HOSTKIT_TRANSACTION_NAME}-$$"

    # --on-active creates <unit>.timer and a matching <unit>.service.
    # The rollback script is executed by PID 1, independent of the initiating SSH session.
    systemd-run \
        --quiet \
        --unit="$unit" \
        --on-active="${timeout}s" \
        --timer-property=AccuracySec=1s \
        --collect \
        "$rollback_script" || return 1

    HOSTKIT_TRANSACTION_UNIT="$unit"
    HOSTKIT_TRANSACTION_ROLLBACK="$rollback_script"
    HOSTKIT_TRANSACTION_ARMED=1
}

transaction_disarm() {
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 1 ] || return 0
    local unit="${HOSTKIT_TRANSACTION_UNIT:?}"

    # Stopping the timer first prevents future activation. A service may already
    # have started at the timeout boundary, so stop it as well.
    systemctl stop "${unit}.timer" >/dev/null 2>&1 || {
        die "Failed to disarm rollback timer: ${unit}.timer"
        return 1
    }
    systemctl stop "${unit}.service" >/dev/null 2>&1 || true
    systemctl reset-failed "${unit}.service" >/dev/null 2>&1 || true

    HOSTKIT_TRANSACTION_ARMED=0
    HOSTKIT_TRANSACTION_UNIT=
    HOSTKIT_TRANSACTION_ROLLBACK=
}

transaction_commit() {
    transaction_disarm
}

transaction_rollback() {
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 1 ] || { die "Transaction is not armed."; return 1; }
    local rollback_script="${HOSTKIT_TRANSACTION_ROLLBACK:-}"
    [ -x "$rollback_script" ] || { die "Rollback script is not executable: $rollback_script"; return 1; }

    transaction_disarm || return 1
    "$rollback_script"
}
