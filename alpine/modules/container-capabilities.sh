# Alpine CONTAINER host capability inspection.
# These checks do not mutate the host.

container_capability_cgroup2() {
    [ -r /proc/filesystems ] && grep -Eq '(^|[[:space:]])cgroup2$' /proc/filesystems
}

container_capability_overlay() {
    [ -r /proc/filesystems ] && grep -Eq '(^|[[:space:]])overlay$' /proc/filesystems
}

container_capability_namespaces() {
    local key
    for key in max_mnt_namespaces max_net_namespaces max_pid_namespaces max_uts_namespaces; do
        [ -r "/proc/sys/user/$key" ] || return 1
        [ "$(cat "/proc/sys/user/$key")" -gt 0 ] 2>/dev/null || return 1
    done
}

container_capabilities_report() {
    local failed=0
    container_capability_cgroup2 || { log_warn "Kernel does not advertise cgroup v2 support."; failed=1; }
    container_capability_overlay || { log_warn "Kernel does not advertise overlayfs support."; failed=1; }
    container_capability_namespaces || { log_warn "Required namespace capacity is unavailable."; failed=1; }
    return "$failed"
}
