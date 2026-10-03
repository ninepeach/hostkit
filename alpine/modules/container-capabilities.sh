# Alpine CONTAINER host capability inspection.
# These checks do not mutate the host.

container_proc_root() { printf '%s' "${HOSTKIT_PROC_ROOT:-/proc}"; }

container_capability_cgroup2() {
    local root
    root="$(container_proc_root)"
    [ -r "$root/filesystems" ] &&
        grep -Eq '(^|[[:space:]])cgroup2$' "$root/filesystems"
}

container_capability_overlay() {
    local root
    root="$(container_proc_root)"
    [ -r "$root/filesystems" ] &&
        grep -Eq '(^|[[:space:]])overlay$' "$root/filesystems"
}

container_capability_namespaces() {
    local root key
    root="$(container_proc_root)"
    for key in max_mnt_namespaces max_net_namespaces max_pid_namespaces max_uts_namespaces; do
        [ -r "$root/sys/user/$key" ] || return 1
        [ "$(cat "$root/sys/user/$key")" -gt 0 ] 2>/dev/null || return 1
    done
}

container_capabilities_report() {
    local failed=0
    container_capability_cgroup2 ||
        { log_warn "Kernel does not advertise cgroup v2 support."; failed=1; }
    container_capability_overlay ||
        { log_warn "Kernel does not advertise overlayfs support."; failed=1; }
    container_capability_namespaces ||
        { log_warn "Required namespace capacity is unavailable."; failed=1; }
    return "$failed"
}
