# Hostname mechanisms.

hostname_validate() {
    local value="$1"
    [ -n "$value" ] || return 1
    [ "${#value}" -le 253 ] || return 1
    printf '%s' "$value" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$' || return 1
    ! printf '%s' "$value" | grep -Eq '\.\.'
}

hostname_set() {
    local value="$1"
    hostname_validate "$value" || { die "Invalid hostname: $value"; return 1; }
    [ "$(hostnamectl --static 2>/dev/null)" = "$value" ] && return 0
    hostnamectl set-hostname "$value"
}
