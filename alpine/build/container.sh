# HostKit Alpine CONTAINER product definition.
# This is a build-time host-image profile. It does not install or manage a container runtime.

MODULES=(
    core
    container-config
    container-capabilities
    container-sysctl
)

hostkit_main() {
    require_root
    require_alpine
    require_command sysctl grep cat mktemp install cmp

    [ "$#" -ge 1 ] && [ "$#" -le 2 ] || {
        die "Usage: alpine-container.sh --check [CONFIG] | CONFIG"
        return 2
    }

    if [ "$1" = "--check" ]; then
        [ "$#" -eq 2 ] || { die "Usage: alpine-container.sh --check CONFIG"; return 2; }
        container_config_parse "$2"
        container_sysctl_validate_runtime_capabilities
        container_capabilities_report || {
            die "Container host kernel capabilities are incomplete."
            return 1
        }
        log_ok "Alpine CONTAINER configuration and host capabilities are valid."
        log_warn "Check mode does not write persistent tuning."
        return 0
    fi

    [ "$#" -eq 1 ] || { die "Usage: alpine-container.sh CONFIG"; return 2; }
    container_config_parse "$1"
    container_sysctl_validate_runtime_capabilities
    container_capabilities_report || {
        die "Container host kernel capabilities are incomplete."
        return 1
    }
    container_sysctl_install
    log_ok "Alpine CONTAINER build-time profile installed."
    log_info "Persistent tuning will take effect through the host sysctl lifecycle."
    log_warn "HostKit did not install, configure, start, or manage a container runtime."
}
