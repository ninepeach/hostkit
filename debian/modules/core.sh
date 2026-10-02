# HostKit core mechanisms.
# Sourcing this file must not change host or caller shell state.

log_info()  { printf 'INFO  %s\n' "$*"; }
log_warn()  { printf 'WARN  %s\n' "$*" >&2; }
log_error() { printf 'ERROR %s\n' "$*" >&2; }
log_ok()    { printf 'OK    %s\n' "$*"; }

die() {
    log_error "$*"
    return 1
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "HostKit must run as root."
        return 1
    fi
}

require_command() {
    local command_name
    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            die "Required command not found: $command_name"
            return 1
        fi
    done
}

require_debian_13() {
    if [ ! -r /etc/os-release ]; then
        die "Cannot identify operating system: /etc/os-release is unavailable."
        return 1
    fi

    local id version_id
    id="$(. /etc/os-release; printf '%s' "${ID:-}")"
    version_id="$(. /etc/os-release; printf '%s' "${VERSION_ID:-}")"

    if [ "$id" != "debian" ] || [ "$version_id" != "13" ]; then
        die "Unsupported operating system: Debian 13 is required."
        return 1
    fi
}
