# Read-only host health checks.

health_failed_units_count() {
    systemctl --failed --no-legend --plain 2>/dev/null | awk 'NF {count++} END {print count+0}'
}

health_root_free_kb() {
    df -Pk / | awk 'NR == 2 {print $4}'
}
