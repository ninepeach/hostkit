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
    HOSTKIT_TRANSACTION_GUARD=
    HOSTKIT_TRANSACTION_WRAPPER=
}

transaction_arm() {
    local rollback_script="$1"
    local timeout="${2:-180}"

    [ -n "${HOSTKIT_TRANSACTION_NAME:-}" ] || { die "Transaction has not been started."; return 1; }
    transaction_validate_timeout "$timeout" || { die "Invalid rollback timeout: $timeout"; return 1; }
    [ -x "$rollback_script" ] || { die "Rollback script is not executable: $rollback_script"; return 1; }
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 0 ] || { die "Transaction is already armed."; return 1; }

    local unit="hostkit-rollback-${HOSTKIT_TRANSACTION_NAME}-$"
    local guard="/run/${unit}.armed"
    local wrapper="/run/${unit}.sh"
    cat >"$wrapper" <<EOF
#!/usr/bin/env bash
set -eu
[ -e "$guard" ] || exit 0
rm -f "$guard" "$wrapper"
exec "$rollback_script"
EOF
    chmod 700 "$wrapper" || { rm -f "$wrapper"; return 1; }
    : >"$guard" || { rm -f "$wrapper"; return 1; }
    chmod 600 "$guard" || { rm -f "$guard" "$wrapper"; return 1; }

    systemd-run \
        --quiet \
        --unit="$unit" \
        --on-active="${timeout}s" \
        --timer-property=AccuracySec=1s \
        --collect \
        "$wrapper" || { rm -f "$guard" "$wrapper"; return 1; }

    HOSTKIT_TRANSACTION_UNIT="$unit"
    HOSTKIT_TRANSACTION_ROLLBACK="$rollback_script"
    HOSTKIT_TRANSACTION_GUARD="$guard"
    HOSTKIT_TRANSACTION_WRAPPER="$wrapper"
    HOSTKIT_TRANSACTION_ARMED=1
}

transaction_disarm() {
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 1 ] || return 0
    local unit="${HOSTKIT_TRANSACTION_UNIT:?}"
    local guard="${HOSTKIT_TRANSACTION_GUARD:-}"
    local wrapper="${HOSTKIT_TRANSACTION_WRAPPER:-}"

    # Remove the commit guard before touching systemd. Even if the timer races
    # with commit, a rollback process that has not crossed this check becomes a no-op.
    [ -z "$guard" ] || rm -f "$guard" || {
        die "Failed to remove rollback guard: $guard"
        return 1
    }

    if ! systemctl stop "${unit}.timer" >/dev/null 2>&1; then
        # A missing timer after the guard is removed means it already fired or
        # was collected. The guard still prevents a not-yet-started rollback.
        if systemctl status "${unit}.timer" >/dev/null 2>&1; then
            die "Failed to disarm rollback timer: ${unit}.timer"
            return 1
        fi
    fi
    # Do not kill an already-running rollback service here: it may have crossed
    # the guard before commit. Let it finish rather than interrupt recovery.
    systemctl reset-failed "${unit}.service" >/dev/null 2>&1 || true
    # The wrapper may already be executing. Leave it on /run until the next
    # boot rather than unlinking a recovery executable at the commit boundary.

    HOSTKIT_TRANSACTION_ARMED=0
    HOSTKIT_TRANSACTION_UNIT=
    HOSTKIT_TRANSACTION_ROLLBACK=
    HOSTKIT_TRANSACTION_GUARD=
    HOSTKIT_TRANSACTION_WRAPPER=
}

transaction_commit() {
    transaction_disarm
}

transaction_rollback() {
    [ "${HOSTKIT_TRANSACTION_ARMED:-0}" -eq 1 ] || { die "Transaction is not armed."; return 1; }
    local rollback_script="${HOSTKIT_TRANSACTION_ROLLBACK:-}"
    [ -x "$rollback_script" ] || { die "Rollback script is not executable: $rollback_script"; return 1; }

    # Explicit rollback owns recovery now; remove the scheduled guard/timer,
    # then execute the product-owned rollback synchronously.
    transaction_disarm || return 1
    "$rollback_script"
}
