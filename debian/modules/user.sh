# Local user mechanisms.

user_validate_name() {
    local value="$1"
    printf '%s' "$value" | grep -Eq '^[a-z_][a-z0-9_-]{0,31}$'
}

user_exists() {
    id "$1" >/dev/null 2>&1
}

user_ensure() {
    local value="$1"
    user_validate_name "$value" || { die "Invalid user name: $value"; return 1; }
    user_exists "$value" && return 0
    useradd --create-home --shell /bin/bash "$value"
}
