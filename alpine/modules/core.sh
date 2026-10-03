# HostKit Alpine core mechanisms.
# Sourcing this file must not change host or caller shell state.

log_info()  { printf 'INFO  %s\n' "$*"; }
log_warn()  { printf 'WARN  %s\n' "$*" >&2; }
log_error() { printf 'ERROR %s\n' "$*" >&2; }
log_ok()    { printf 'OK    %s\n' "$*"; }

die() { log_error "$*"; return 1; }

require_root() {
    [ "$(id -u)" -eq 0 ] || { die "HostKit must run as root."; return 1; }
}

require_command() {
    local command_name
    for command_name in "$@"; do
        command -v "$command_name" >/dev/null 2>&1 ||
            { die "Required command not found: $command_name"; return 1; }
    done
}

require_alpine() {
    [ -r /etc/os-release ] || { die "Cannot identify operating system."; return 1; }
    local id
    id="$(. /etc/os-release; printf '%s' "${ID:-}")"
    [ "$id" = "alpine" ] || { die "Unsupported operating system: Alpine Linux is required."; return 1; }
}
