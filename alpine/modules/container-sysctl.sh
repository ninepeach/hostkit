# Alpine CONTAINER sysctl mechanisms.
# Values are explicit policy inputs. HostKit does not invent workload-specific tuning.

container_sysctl_hostkit_owned() {
    local path="$1"
    [ -f "$path" ] && IFS= read -r first <"$path" &&
        [ "$first" = "# Managed by HostKit. Do not edit manually." ]
}

container_sysctl_emit() {
    local key="$1" value="$2"
    [ "$value" = keep ] || printf '%s = %s\n' "$key" "$value"
}

container_sysctl_render() {
    printf '# Managed by HostKit. Do not edit manually.\n'
    printf '# Alpine CONTAINER build-time host profile.\n'
    container_sysctl_emit fs.inotify.max_user_watches "$INOTIFY_MAX_USER_WATCHES"
    container_sysctl_emit fs.inotify.max_user_instances "$INOTIFY_MAX_USER_INSTANCES"
    container_sysctl_emit fs.inotify.max_queued_events "$INOTIFY_MAX_QUEUED_EVENTS"
    container_sysctl_emit net.core.somaxconn "$SOMAXCONN"
    container_sysctl_emit net.netfilter.nf_conntrack_max "$NF_CONNTRACK_MAX"
}

container_sysctl_validate_key_exists() {
    local key="$1" value="$2"
    [ "$value" = keep ] && return 0
    sysctl -n "$key" >/dev/null 2>&1 ||
        { die "Requested sysctl is unavailable on this kernel: $key"; return 1; }
}

container_sysctl_validate_runtime_capabilities() {
    container_sysctl_validate_key_exists fs.inotify.max_user_watches "$INOTIFY_MAX_USER_WATCHES" &&
    container_sysctl_validate_key_exists fs.inotify.max_user_instances "$INOTIFY_MAX_USER_INSTANCES" &&
    container_sysctl_validate_key_exists fs.inotify.max_queued_events "$INOTIFY_MAX_QUEUED_EVENTS" &&
    container_sysctl_validate_key_exists net.core.somaxconn "$SOMAXCONN" &&
    container_sysctl_validate_key_exists net.netfilter.nf_conntrack_max "$NF_CONNTRACK_MAX"
}

container_sysctl_install() {
    local path="${HOSTKIT_CONTAINER_SYSCTL_FILE:-/etc/sysctl.d/90-hostkit-container.conf}"
    if [ -e "$path" ] && ! container_sysctl_hostkit_owned "$path"; then
        die "Refusing to overwrite sysctl file not owned by HostKit: $path"
        return 1
    fi

    mkdir -p "$(dirname "$path")"
    local tmp
    tmp="$(mktemp)"
    container_sysctl_render >"$tmp"

    if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        return 0
    fi
    install -m 0644 "$tmp" "$path"
    rm -f "$tmp"
}
