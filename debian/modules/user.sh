# Local user mechanisms.

user_validate_name() {
    local value="$1"
    printf '%s' "$value" | grep -Eq '^[a-z_][a-z0-9_-]{0,31}$'
}

user_exists() {
    id "$1" >/dev/null 2>&1
}

user_home() {
    getent passwd "$1" | awk -F: '{print $6}'
}

user_shell() {
    getent passwd "$1" | awk -F: '{print $7}'
}

user_is_compatible_admin() {
    local value="$1" home shell
    user_exists "$value" || return 1
    home="$(user_home "$value")"
    shell="$(user_shell "$value")"
    [ -n "$home" ] && [ "$home" != "/" ] && [ -d "$home" ] || return 1
    case "$shell" in /bin/bash|/bin/sh) return 0 ;; *) return 1 ;; esac
}

user_ensure() {
    local value="$1"
    user_validate_name "$value" || { die "Invalid user name: $value"; return 1; }

    if user_exists "$value"; then
        user_is_compatible_admin "$value" || {
            die "Existing user is incompatible with HostKit administrative access: $value"
            return 1
        }
        return 0
    fi

    useradd --create-home --shell /bin/bash "$value"
}
